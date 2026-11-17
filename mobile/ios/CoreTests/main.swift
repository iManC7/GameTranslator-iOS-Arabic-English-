// SPDX-License-Identifier: AGPL-3.0-only
// Core testlerinin giriş noktası (run.sh).
import Foundation

TextMatchTest.run()
OcrNoiseTest.run()
SubtitleStabilizerTest.run()
SubtitlePipelineTest.run()
ReadSchedulerTest.run()
GlossaryTest.run()
TurkishSuffixTest.run()
TermProtectionTest.run()
SpeakerPrefixTest.run()
SpeakerNameTest.run()
ButtonHintsTest.run()
// Bellek ölçümü önce: başka paket denemelerinin bıraktığı bellek ölçüme karışmasın.
PackMemoryTest.run()
PackKeyTest.run()
GamePackTest.run()
PackLookupTest.run()
PackLookupFuzzyTest.run()
PackFuzzyTest.run()
PackPipelineTest.run()
PackStoreTest.run()
TestRun.finish()
