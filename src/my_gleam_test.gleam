import gleam/erlang/process
import simplifile.{read}
import sqlight
import mist
import app/article_controller
import web.{type Context}
import wisp.{type Request, type Response}

pub fn init(conn: sqlight.Connection) -> Result(Nil, sqlight.Error) {
	let assert Ok(sql) = read("init.sql")
	let assert Ok(Nil) = sqlight.exec(sql, conn)
}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)
  case wisp.path_segments(req) {
		["articles"] -> article_controller.index(req, ctx)
    _ -> wisp.not_found()
  }
}

pub fn main() {
	wisp.configure_logger()
	let secret_key_base = wisp.random_string(64)

	use conn <- sqlight.with_connection(":memory:")
	let context = web.Context(conn)
	let assert Ok(_) = init(conn)

	let handler = handle_request(_, context)

  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
