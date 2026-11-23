import XCTest
@testable import PomoEngine

final class StatsCalculatorTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Mexico_City")!
        return calendar
    }()

    private func date(_ day: Int, _ hour: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    private func work(_ day: Int, completed: Bool = true, minutes: Int = 25) -> SessionSample {
        SessionSample(start: date(day), duration: minutes * 60, type: .work, wasCompleted: completed)
    }

    private func rest(_ day: Int) -> SessionSample {
        SessionSample(start: date(day, 11), duration: 300, type: .shortBreak, wasCompleted: true)
    }

    func testPomodorosCountCompletedWorkEvenWithoutBreaks() {
        let stats = StatsCalculator.dayStats(for: date(9), sessions: [work(9), work(9), work(9, completed: false, minutes: 10)], calendar: calendar)
        XCTAssertEqual(stats.pomodoros, 2)
        XCTAssertEqual(stats.focusSeconds, 60 * 60)
    }

    func testBreaksDoNotCountAsFocus() {
        let stats = StatsCalculator.dayStats(for: date(9), sessions: [work(9), rest(9)], calendar: calendar)
        XCTAssertEqual(stats.pomodoros, 1)
        XCTAssertEqual(stats.focusSeconds, 25 * 60)
    }

    func testLastDaysCoversExactlySevenDaysAcrossWeekBoundary() {
        // Nov 9 2026 is a Monday: the previous days belong to the previous week
        let days = StatsCalculator.lastDays(7, endingOn: date(9), sessions: [work(3), work(8), work(9)], calendar: calendar)
        XCTAssertEqual(days.count, 7)
        XCTAssertEqual(days.first?.day, calendar.startOfDay(for: date(3)))
        XCTAssertEqual(days.map(\.pomodoros), [1, 0, 0, 0, 0, 1, 1])
    }

    func testStreakCountsConsecutiveDays() {
        let sessions = [work(5), work(6), work(7), work(8), work(9)]
        XCTAssertEqual(StatsCalculator.streak(endingOn: date(9), sessions: sessions, calendar: calendar), 5)
    }

    func testStreakStaysAliveBeforeTodaysFirstSession() {
        let sessions = [work(7), work(8)]
        XCTAssertEqual(StatsCalculator.streak(endingOn: date(9, 8), sessions: sessions, calendar: calendar), 2)
    }

    func testStreakBreaksAfterMissedDay() {
        let sessions = [work(6), work(7)]
        XCTAssertEqual(StatsCalculator.streak(endingOn: date(9), sessions: sessions, calendar: calendar), 0)
    }

    func testSkippedSessionsDoNotKeepStreak() {
        XCTAssertEqual(StatsCalculator.streak(endingOn: date(9), sessions: [work(9, completed: false)], calendar: calendar), 0)
    }

    func testSnapshotFromYesterdayKeepsStreakButResetsToday() {
        let snapshot = StatsCalculator.snapshot(on: date(8), sessions: [work(7), work(8)], calendar: calendar)
        let today = snapshot.values(on: date(9), calendar: calendar)
        XCTAssertEqual(today.pomodoros, 0)
        XCTAssertEqual(today.streak, 2)
        let later = snapshot.values(on: date(10), calendar: calendar)
        XCTAssertEqual(later.streak, 0)
    }
}
