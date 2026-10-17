/*
 * Copyright (C) 2026 The Raspberry-Pi-5-Android Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#define LOG_TAG "android.hardware.power-service.rpi5"

#include "Power.h"

#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/strings.h>

#include <algorithm>
#include <cstdio>

namespace aidl::android::hardware::power::impl::rpi5 {

using ::android::base::ReadFileToString;
using ::android::base::Trim;
using ::android::base::WriteStringToFile;

namespace {

constexpr char kCpufreqDir[] = "/sys/devices/system/cpu/cpufreq/policy0/";

std::string ReadNode(const char* name) {
    std::string value;
    if (!ReadFileToString(std::string(kCpufreqDir) + name, &value)) {
        PLOG(ERROR) << "Failed to read " << kCpufreqDir << name;
        return "";
    }
    return Trim(value);
}

ndk::ScopedAStatus Unsupported() {
    return ndk::ScopedAStatus::fromExceptionCode(EX_UNSUPPORTED_OPERATION);
}

}  // namespace

CpuBoost::CpuBoost() {
    normal_min_ = ReadNode("scaling_min_freq");
    boost_min_ = ReadNode("cpuinfo_max_freq");
    LOG(INFO) << "cpufreq policy0: normal minimum " << normal_min_ << " kHz, boost minimum "
              << boost_min_ << " kHz";
    worker_ = std::thread(&CpuBoost::Loop, this);
}

CpuBoost::~CpuBoost() {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        exit_ = true;
    }
    cv_.notify_all();
    worker_.join();
}

void CpuBoost::Interaction(std::chrono::milliseconds duration) {
    std::lock_guard<std::mutex> lock(mutex_);
    interaction_deadline_ = std::max(interaction_deadline_, Clock::now() + duration);
    interaction_count_++;
    cv_.notify_all();
}

void CpuBoost::Launch(bool enabled) {
    std::lock_guard<std::mutex> lock(mutex_);
    launch_deadline_ = enabled ? Clock::now() + kMaxBoost : Clock::time_point::min();
    if (enabled) launch_count_++;
    cv_.notify_all();
}

void CpuBoost::Loop() {
    std::unique_lock<std::mutex> lock(mutex_);
    while (!exit_) {
        const Clock::time_point deadline = std::max(interaction_deadline_, launch_deadline_);
        const bool want = deadline > Clock::now();
        if (want != boosted_) Apply(want);
        if (want) {
            cv_.wait_until(lock, deadline);
        } else {
            cv_.wait(lock);
        }
    }
    if (boosted_) Apply(false);
}

// Called with mutex_ held; a sysfs write is short.
void CpuBoost::Apply(bool boost) {
    const std::string& value = boost ? boost_min_ : normal_min_;
    if (value.empty()) return;
    if (!WriteStringToFile(value, std::string(kCpufreqDir) + "scaling_min_freq")) {
        PLOG(ERROR) << "Failed to write scaling_min_freq " << value;
        return;
    }
    boosted_ = boost;
}

void CpuBoost::Dump(int fd) {
    std::lock_guard<std::mutex> lock(mutex_);
    const Clock::time_point now = Clock::now();
    auto remaining_ms = [now](Clock::time_point t) -> long long {
        if (t <= now) return 0;
        return std::chrono::duration_cast<std::chrono::milliseconds>(t - now).count();
    };
    dprintf(fd, "cpufreq policy0: normal min %s kHz, boost min %s kHz\n", normal_min_.c_str(),
            boost_min_.c_str());
    dprintf(fd, "current: scaling_min_freq %s kHz, scaling_cur_freq %s kHz\n",
            ReadNode("scaling_min_freq").c_str(), ReadNode("scaling_cur_freq").c_str());
    dprintf(fd, "boosted: %s, interaction remaining %lld ms, launch remaining %lld ms\n",
            boosted_ ? "yes" : "no", remaining_ms(interaction_deadline_),
            remaining_ms(launch_deadline_));
    dprintf(fd, "INTERACTION boosts: %llu, LAUNCH boosts: %llu\n",
            static_cast<unsigned long long>(interaction_count_),
            static_cast<unsigned long long>(launch_count_));
}

ndk::ScopedAStatus Power::setMode(Mode type, bool enabled) {
    if (type == Mode::LAUNCH) boost_.Launch(enabled);
    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus Power::isModeSupported(Mode type, bool* _aidl_return) {
    *_aidl_return = type == Mode::LAUNCH;
    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus Power::setBoost(Boost type, int32_t durationMs) {
    if (type == Boost::INTERACTION) {
        const std::chrono::milliseconds duration =
                durationMs > 0 ? std::min(std::chrono::milliseconds(durationMs), kMaxBoost)
                               : kDefaultInteractionBoost;
        boost_.Interaction(duration);
    }
    return ndk::ScopedAStatus::ok();
}

ndk::ScopedAStatus Power::isBoostSupported(Boost type, bool* _aidl_return) {
    *_aidl_return = type == Boost::INTERACTION;
    return ndk::ScopedAStatus::ok();
}

// Performance hint sessions (ADPF) are not supported.
ndk::ScopedAStatus Power::createHintSession(int32_t, int32_t, const std::vector<int32_t>&,
                                            int64_t,
                                            std::shared_ptr<IPowerHintSession>* _aidl_return) {
    *_aidl_return = nullptr;
    return Unsupported();
}

ndk::ScopedAStatus Power::createHintSessionWithConfig(
        int32_t, int32_t, const std::vector<int32_t>&, int64_t, SessionTag, SessionConfig*,
        std::shared_ptr<IPowerHintSession>* _aidl_return) {
    *_aidl_return = nullptr;
    return Unsupported();
}

ndk::ScopedAStatus Power::getSessionChannel(int32_t, int32_t, ChannelConfig*) {
    return Unsupported();
}

ndk::ScopedAStatus Power::closeSessionChannel(int32_t, int32_t) {
    return Unsupported();
}

ndk::ScopedAStatus Power::getHintSessionPreferredRate(int64_t* outNanoseconds) {
    *outNanoseconds = -1;
    return Unsupported();
}

binder_status_t Power::dump(int fd, const char**, uint32_t) {
    boost_.Dump(fd);
    return STATUS_OK;
}

}  // namespace aidl::android::hardware::power::impl::rpi5
