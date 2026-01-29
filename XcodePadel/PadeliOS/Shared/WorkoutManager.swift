import Foundation
import HealthKit
import Combine

enum WorkoutState {
    case idle
    case active
    case paused
}

class WorkoutManager: NSObject, ObservableObject {
    @Published var state: WorkoutState = .idle
    @Published var heartRate: Double = 0
    @Published var activeCalories: Double = 0
    
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    func requestAuthorization() {
        let typesToShare: Set = [
            HKObjectType.workoutType()
        ]
        
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            if !success {
                print("HealthKit Authorization Failed: \(String(describing: error))")
            }
        }
    }
    
    func startWorkout() {
        guard state == .idle else { return }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .tennis
        configuration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
            
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                         workoutConfiguration: configuration)
            
            session?.delegate = self
            builder?.delegate = self
            
            let startDate = Date()
            session?.startActivity(with: startDate)
            builder?.beginCollection(withStart: startDate) { (success, error) in
                // The workout has started.
            }
            
            DispatchQueue.main.async {
                self.state = .active
            }
        } catch {
            print("Failed to start workout: \(error)")
        }
    }
    
    func endWorkout() {
        guard state != .idle else { return }
        
        session?.end()
        builder?.endCollection(withEnd: Date()) { (success, error) in
            self.builder?.finishWorkout { (workout, error) in
                DispatchQueue.main.async {
                    self.state = .idle
                }
            }
        }
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // Handle state changes
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        // Handle error
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle events
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf types: Set<HKSampleType>) {
        for type in types {
            guard let quantityType = type as? HKQuantityType else { continue }
            guard let statistics = workoutBuilder.statistics(for: quantityType) else { continue }
            
            DispatchQueue.main.async {
                switch type.identifier {
                case HKQuantityTypeIdentifier.heartRate.rawValue:
                    let value = statistics.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    self.heartRate = value ?? 0
                case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                    let value = statistics.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie())
                    self.activeCalories = value ?? 0
                default:
                    return
                }
            }
        }
    }
}
