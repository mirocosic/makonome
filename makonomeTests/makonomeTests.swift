//
//  makonomeTests.swift
//  makonomeTests
//
//  Created by Miro on 23.06.2025..
//

import Testing
import SwiftUI
@testable import makonome

struct makonomeTests {

    
    // MARK: - Metronome Tests
    
    // Test NoteSubdivision enum properties
    @Test func testNoteSubdivisionSymbols() async throws {
        #expect(NoteSubdivision.quarter.symbol == "♩")
        #expect(NoteSubdivision.eighth.symbol == "♫")
        #expect(NoteSubdivision.sixteenth.symbol == "♬")
        #expect(NoteSubdivision.triplets.symbol == "♪♪♪")
    }
    
    @Test func testNoteSubdivisionMultipliers() async throws {
        #expect(NoteSubdivision.quarter.multiplier == 1.0)
        #expect(NoteSubdivision.eighth.multiplier == 2.0)
        #expect(NoteSubdivision.sixteenth.multiplier == 4.0)
        #expect(NoteSubdivision.triplets.multiplier == 3.0)
    }
    
    @Test func testNoteSubdivisionRawValues() async throws {
        #expect(NoteSubdivision.quarter.rawValue == "Quarter Notes")
        #expect(NoteSubdivision.eighth.rawValue == "Eighth Notes")
        #expect(NoteSubdivision.sixteenth.rawValue == "Sixteenth Notes")
        #expect(NoteSubdivision.triplets.rawValue == "Triplets")
    }
    
    @Test func testNoteSubdivisionAllCases() async throws {
        let allCases = NoteSubdivision.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.quarter))
        #expect(allCases.contains(.eighth))
        #expect(allCases.contains(.sixteenth))
        #expect(allCases.contains(.triplets))
    }
    
    // Test metronome timing calculations  
    @Test func testMetronomeTimingCalculations() async throws {
        // Test quarter notes at 120 BPM (should be 0.5 seconds per beat)
        let quarterInterval = MetronomeView.calculateInterval(bpm: 120, subdivision: .quarter)
        #expect(quarterInterval == 0.5)
        
        // Test eighth notes at 120 BPM (should be 0.25 seconds per beat)
        let eighthInterval = MetronomeView.calculateInterval(bpm: 120, subdivision: .eighth)
        #expect(eighthInterval == 0.25)
        
        // Test sixteenth notes at 120 BPM (should be 0.125 seconds per beat)
        let sixteenthInterval = MetronomeView.calculateInterval(bpm: 120, subdivision: .sixteenth)
        #expect(sixteenthInterval == 0.125)
        
        // Test triplets at 120 BPM (should be 0.166... seconds per beat)
        let tripletInterval = MetronomeView.calculateInterval(bpm: 120, subdivision: .triplets)
        #expect(abs(tripletInterval - (0.5 / 3.0)) < 0.001)
    }
    
    @Test func testMetronomeTimingEdgeCases() async throws {
        // Test very slow BPM
        let slowQuarter = MetronomeView.calculateInterval(bpm: 40, subdivision: .quarter)
        #expect(slowQuarter == 1.5)
        
        // Test very fast BPM  
        let fastQuarter = MetronomeView.calculateInterval(bpm: 400, subdivision: .quarter)
        #expect(fastQuarter == 0.15)
        
        // Test fast eighths
        let fastEighth = MetronomeView.calculateInterval(bpm: 200, subdivision: .eighth)
        #expect(fastEighth == 0.15)
    }
    
    // Test accent beat logic
    @Test func testAccentBeatLogicQuarter() async throws {
        // Quarter notes: accent on beats 1, 5, 9, etc.
        #expect(MetronomeView.isAccentedBeat(beatCount: 1, subdivision: .quarter) == true)
        #expect(MetronomeView.isAccentedBeat(beatCount: 2, subdivision: .quarter) == false)
        #expect(MetronomeView.isAccentedBeat(beatCount: 3, subdivision: .quarter) == false)
        #expect(MetronomeView.isAccentedBeat(beatCount: 4, subdivision: .quarter) == false)
        #expect(MetronomeView.isAccentedBeat(beatCount: 5, subdivision: .quarter) == true)
    }
    
    @Test func testAccentBeatLogicEighth() async throws {
        // Eighth notes: accent on beats 1, 3, 5, 7, etc.
        #expect(MetronomeView.isAccentedBeat(beatCount: 1, subdivision: .eighth) == true)
        #expect(MetronomeView.isAccentedBeat(beatCount: 2, subdivision: .eighth) == false)
        #expect(MetronomeView.isAccentedBeat(beatCount: 3, subdivision: .eighth) == true)
        #expect(MetronomeView.isAccentedBeat(beatCount: 4, subdivision: .eighth) == false)
        #expect(MetronomeView.isAccentedBeat(beatCount: 5, subdivision: .eighth) == true)
    }
    
    @Test func testAccentBeatLogicSixteenth() async throws {
        // Sixteenth notes: accent on beats 1, 5, 9, 13, etc.
        #expect(MetronomeView.isAccentedBeat(beatCount: 1, subdivision: .sixteenth) == true)
        #expect(MetronomeView.isAccentedBeat(beatCount: 2, subdivision: .sixteenth) == false)
        #expect(MetronomeView.isAccentedBeat(beatCount: 3, subdivision: .sixteenth) == false)
        #expect(MetronomeView.isAccentedBeat(beatCount: 4, subdivision: .sixteenth) == false)
        #expect(MetronomeView.isAccentedBeat(beatCount: 5, subdivision: .sixteenth) == true)
    }
    
    @Test func testAccentBeatLogicTriplets() async throws {
        // Triplets: accent on beats 1, 4, 7, 10, etc. (every 3rd beat starting from 1)
        #expect(MetronomeView.isAccentedBeat(beatCount: 1, subdivision: .triplets) == true)
        #expect(MetronomeView.isAccentedBeat(beatCount: 2, subdivision: .triplets) == false)
        #expect(MetronomeView.isAccentedBeat(beatCount: 3, subdivision: .triplets) == false)
        #expect(MetronomeView.isAccentedBeat(beatCount: 4, subdivision: .triplets) == true)
        #expect(MetronomeView.isAccentedBeat(beatCount: 5, subdivision: .triplets) == false)
        #expect(MetronomeView.isAccentedBeat(beatCount: 6, subdivision: .triplets) == false)
        #expect(MetronomeView.isAccentedBeat(beatCount: 7, subdivision: .triplets) == true)
    }

}
