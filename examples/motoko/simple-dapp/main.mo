import Array "mo:base/Array";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Result "mo:base/Result";

actor Counter {
  // Types
  type Result<T, E> = Result.Result<T, E>;
  type Time = Time.Time;

  // Error types
  type Error = {
    #Unauthorized;
    #Underflow;
    #NotFound;
  };

  // Stable variables (persist across upgrades)
  stable var counter : Nat = 0;
  stable var owner : Principal = Principal.fromText("aaaaa-aa");
  stable var totalIncrements : Nat = 0;
  stable var totalDecrements : Nat = 0;

  // Stable array for user stats (for upgrades)
  stable var userStatsEntries : [(Principal, UserStats)] = [];

  // User statistics
  type UserStats = {
    actionCount: Nat;
    lastAction: Time;
  };

  // User stats map
  var userStats = HashMap.HashMap<Principal, UserStats>(
    10,
    Principal.equal,
    Principal.hash
  );

  // History entry
  type HistoryEntry = {
    action: Text;
    value: Nat;
    timestamp: Time;
    caller: Principal;
  };

  // History (limited to last 100 entries)
  stable var history : [HistoryEntry] = [];
  let MAX_HISTORY : Nat = 100;

  // Initialize owner on first deploy
  system func preupgrade() {
    userStatsEntries := Iter.toArray(userStats.entries());
  };

  system func postupgrade() {
    userStats := HashMap.fromIter<Principal, UserStats>(
      userStatsEntries.vals(),
      10,
      Principal.equal,
      Principal.hash
    );
    userStatsEntries := [];
  };

  // Public query functions (read-only, fast)

  public query func getCounter() : async Nat {
    counter
  };

  public query func getOwner() : async Principal {
    owner
  };

  public query func getTotalIncrements() : async Nat {
    totalIncrements
  };

  public query func getTotalDecrements() : async Nat {
    totalDecrements
  };

  public query func getUserStats(user: Principal) : async ?UserStats {
    userStats.get(user)
  };

  public query func getHistory() : async [HistoryEntry] {
    history
  };

  public query func isOwner(caller: Principal) : async Bool {
    Principal.equal(caller, owner)
  };

  // Public update functions (modify state)

  public shared(msg) func increment() : async Nat {
    let caller = msg.caller;

    counter += 1;
    totalIncrements += 1;

    updateUserStats(caller);
    addToHistory("increment", counter, caller);

    counter
  };

  public shared(msg) func decrement() : async Result<Nat, Error> {
    let caller = msg.caller;

    if (counter == 0) {
      return #err(#Underflow);
    };

    counter -= 1;
    totalDecrements += 1;

    updateUserStats(caller);
    addToHistory("decrement", counter, caller);

    #ok(counter)
  };

  public shared(msg) func incrementBy(amount: Nat) : async Nat {
    let caller = msg.caller;

    counter += amount;
    totalIncrements += amount;

    updateUserStats(caller);
    addToHistory("increment_by_" # Nat.toText(amount), counter, caller);

    counter
  };

  public shared(msg) func reset() : async Result<(), Error> {
    let caller = msg.caller;

    if (not Principal.equal(caller, owner)) {
      return #err(#Unauthorized);
    };

    counter := 0;

    addToHistory("reset", counter, caller);

    #ok(())
  };

  public shared(msg) func setCounter(value: Nat) : async Result<Nat, Error> {
    let caller = msg.caller;

    if (not Principal.equal(caller, owner)) {
      return #err(#Unauthorized);
    };

    counter := value;

    addToHistory("set_to_" # Nat.toText(value), counter, caller);

    #ok(counter)
  };

  public shared(msg) func transferOwnership(newOwner: Principal) : async Result<(), Error> {
    let caller = msg.caller;

    if (not Principal.equal(caller, owner)) {
      return #err(#Unauthorized);
    };

    owner := newOwner;

    #ok(())
  };

  // Private helper functions

  private func updateUserStats(user: Principal) {
    let currentStats = userStats.get(user);

    let newStats : UserStats = switch (currentStats) {
      case null {
        {
          actionCount = 1;
          lastAction = Time.now();
        }
      };
      case (?stats) {
        {
          actionCount = stats.actionCount + 1;
          lastAction = Time.now();
        }
      };
    };

    userStats.put(user, newStats);
  };

  private func addToHistory(action: Text, value: Nat, caller: Principal) {
    let entry : HistoryEntry = {
      action = action;
      value = value;
      timestamp = Time.now();
      caller = caller;
    };

    // Keep only last MAX_HISTORY entries
    if (history.size() >= MAX_HISTORY) {
      history := Array.append(
        Array.subArray(history, 1, history.size() - 1),
        [entry]
      );
    } else {
      history := Array.append(history, [entry]);
    };
  };

  // Admin function to clear history
  public shared(msg) func clearHistory() : async Result<(), Error> {
    let caller = msg.caller;

    if (not Principal.equal(caller, owner)) {
      return #err(#Unauthorized);
    };

    history := [];

    #ok(())
  };

  // Statistics function
  public query func getStats() : async {
    counter: Nat;
    totalIncrements: Nat;
    totalDecrements: Nat;
    totalUsers: Nat;
    historySize: Nat;
  } {
    {
      counter = counter;
      totalIncrements = totalIncrements;
      totalDecrements = totalDecrements;
      totalUsers = userStats.size();
      historySize = history.size();
    }
  };
}
