import gleam/otp/actor
import gleam/otp/supervisor
import gleam/int
import gleam/io
import gleam/erlang/process
import periodic

// this just runs two counters in parallel and one is bound to crash but to demonstrate the power of the supervisor, the other one will keep running without being restarted or losing its state because it was also started first
pub fn main() {
  let state = 0

  let _ =
    supervise(fn() {
      let func = fn() { wont_crash(state) }
      periodic.periodically(do: func, waiting: 100)
    })

  let _ =
    supervise(fn() {
      let func = fn() { will_crash(state) }
      periodic.periodically(do: func, waiting: 100)
    })

  process.sleep_forever()
}

fn supervise(start: fn() -> _) -> Result(_, actor.StartError) {
  supervisor.start(fn(children) {
    children
    |> supervisor.add(supervisor.worker(fn(_) { start() }))
  })
}

fn wont_crash(state: Int) {
  let new_state = state + 10
  io.println("count_ten: " <> int.to_string(new_state))
  process.sleep(100)
  wont_crash(new_state)
}

// this function will always crash when it reaches 10
fn will_crash(state: Int) {
  case state {
    x if x == 10 -> {
      io.println("crashing...................................................")
      panic as "count_one has crashed!!!"
    }
    _ -> {
      io.println("count_one: " <> int.to_string(state))
      will_crash(state + 1)
    }
  }
}
