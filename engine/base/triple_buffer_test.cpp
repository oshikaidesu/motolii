// Tests for base/triple_buffer.h. The expected values follow the contract
// written there: the reader is given the newest value published, the same one
// until it asks again, and never one the writer is filling.

#include "base/triple_buffer.h"

#include <gtest/gtest.h>

#include <atomic>
#include <thread>
#include <vector>

namespace motolii {
namespace {

TEST(TripleBuffer, NothingPublishedReadsAnEmptyValue) {
  TripleBuffer<std::vector<double>> b;
  EXPECT_TRUE(b.front().empty());
}

TEST(TripleBuffer, TheReaderIsGivenWhatWasPublished) {
  TripleBuffer<std::vector<double>> b;
  b.back() = {1, 2, 3};
  b.publish();
  EXPECT_EQ((std::vector<double>{1, 2, 3}), b.front());
}

TEST(TripleBuffer, TheNewestOfSeveralIsGivenAndTheOlderAreSkipped) {
  TripleBuffer<int> b;
  for (int i = 1; i <= 5; ++i) b.back() = i, b.publish();
  EXPECT_EQ(5, b.front());
}

TEST(TripleBuffer, WhatTheReaderHoldsStaysWhileTheWriterGoesOn) {
  TripleBuffer<std::vector<double>> b;
  b.back() = {1};
  b.publish();
  const std::vector<double>& held = b.front();
  const double* at = held.data();
  for (int i = 2; i <= 9; ++i) b.back().assign(64, i), b.publish();
  EXPECT_EQ(at, held.data());
  EXPECT_EQ((std::vector<double>{1}), held);
  EXPECT_EQ(9, b.front()[0]);
}

TEST(TripleBuffer, AskingAgainWithNothingNewGivesTheSameValue) {
  TripleBuffer<int> b;
  b.back() = 7, b.publish();
  int* first = &b.front();
  EXPECT_EQ(first, &b.front());
}

TEST(TripleBuffer, TheWriterNeverFillsWhatTheReaderReads) {
  TripleBuffer<std::vector<long>> b;
  std::atomic<bool> stop{false};
  std::thread writer([&] {
    for (long i = 1; !stop.load(); ++i) {
      b.back().assign(256, i);
      b.publish();
    }
  });
  long last = 0;
  bool whole = true, forward = true;
  for (int round = 0; round < 200000; ++round) {
    const std::vector<long>& read = b.front();
    if (read.empty()) continue;
    for (const long v : read) whole = whole && v == read[0];
    forward = forward && read[0] >= last;
    last = read[0];
  }
  stop = true;
  writer.join();
  EXPECT_TRUE(whole) << "a value was read while it was being filled";
  EXPECT_TRUE(forward) << "an older value came after a newer one";
  EXPECT_GT(last, 0);
}

}  // namespace
}  // namespace motolii
