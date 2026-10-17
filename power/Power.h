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

#pragma once

#include <aidl/android/hardware/power/BnPower.h>

#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <mutex>
#include <string>
#include <thread>

namespace aidl::android::hardware::power::impl::rpi5 {

// Boost used when the framework sends INTERACTION without a duration.
constexpr std::chrono::milliseconds kDefaultInteractionBoost{250};
// Upper bound for any single boost, including a LAUNCH that is never ended.
constexpr std::chrono::milliseconds kMaxBoost{5000};

// Raises the cpufreq minimum of policy0 to the maximum frequency while a
// boost is active and restores the original minimum afterwards. The kernel
// has no uclamp support, so the minimum frequency is the available knob.
class CpuBoost {
  public:
    CpuBoost();
    ~CpuBoost();

    void Interaction(std::chrono::milliseconds duration);
    void Launch(bool enabled);
    void Dump(int fd);

  private:
    using Clock = std::chrono::steady_clock;

    void Loop();
    void Apply(bool boost);

    std::string normal_min_;
    std::string boost_min_;

    std::mutex mutex_;
    std::condition_variable cv_;
    Clock::time_point interaction_deadline_ = Clock::time_point::min();
    Clock::time_point launch_deadline_ = Clock::time_point::min();
    bool boosted_ = false;
    bool exit_ = false;
    uint64_t interaction_count_ = 0;
    uint64_t launch_count_ = 0;
    std::thread worker_;
};

class Power : public BnPower {
  public:
    ndk::ScopedAStatus setMode(Mode type, bool enabled) override;
    ndk::ScopedAStatus isModeSupported(Mode type, bool* _aidl_return) override;
    ndk::ScopedAStatus setBoost(Boost type, int32_t durationMs) override;
    ndk::ScopedAStatus isBoostSupported(Boost type, bool* _aidl_return) override;
    ndk::ScopedAStatus createHintSession(int32_t tgid, int32_t uid,
                                         const std::vector<int32_t>& threadIds,
                                         int64_t durationNanos,
                                         std::shared_ptr<IPowerHintSession>* _aidl_return) override;
    ndk::ScopedAStatus createHintSessionWithConfig(
            int32_t tgid, int32_t uid, const std::vector<int32_t>& threadIds,
            int64_t durationNanos, SessionTag tag, SessionConfig* config,
            std::shared_ptr<IPowerHintSession>* _aidl_return) override;
    ndk::ScopedAStatus getSessionChannel(int32_t tgid, int32_t uid,
                                         ChannelConfig* _aidl_return) override;
    ndk::ScopedAStatus closeSessionChannel(int32_t tgid, int32_t uid) override;
    ndk::ScopedAStatus getHintSessionPreferredRate(int64_t* outNanoseconds) override;
    binder_status_t dump(int fd, const char** args, uint32_t numArgs) override;

  private:
    CpuBoost boost_;
};

}  // namespace aidl::android::hardware::power::impl::rpi5
