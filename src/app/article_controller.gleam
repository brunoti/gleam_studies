import app/article.{ArticleDecodeError}
import wisp.{type Request}
import gleam/result.{try}
import gleam/list
import gleam/io
import gleam/json
import gleam/http.{Get, Post}
import sqlight.{type Connection}
import web.{type Context}

pub fn list(db: Connection) {
  let result = {
    use article <- result.map(article.all(db))
    article
    |> list.map(article.to_json)
    |> json.preprocessed_array
    |> json.to_string_builder
  }

  case result {
    Ok(data) -> wisp.json_response(data, 200)
    Error(error) -> {
      io.debug(error)
      let response =
        json.object([#("error", json.string("Could not list articles"))])
        |> json.to_string_builder
      wisp.response(500)
      |> wisp.string_builder_body(response)
    }
  }
}

pub fn index(req: Request, ctx: Context) {
  case req.method {
    Get -> list(ctx.db)
    Post -> create(req, ctx.db)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

pub fn create(req: Request, db: Connection) -> wisp.Response {
  use json <- wisp.require_json(req)
  let result = {
    use a <- try(article.create_data_from_json(json))
    use id <- try(article.create(db, a))
    article.find_by_id(db, id)
  }

  case result {
    Ok(data) ->
      wisp.json_response(
        data
        |> article.to_json
        |> json.to_string_builder,
        201,
      )
    Error(ArticleDecodeError(message)) ->
      wisp.json_response(
        [#("error", json.string(message))]
        |> json.object
        |> json.to_string_builder,
        420,
      )
    Error(error) -> {
      io.debug(error)
      wisp.json_response(
        [#("error", json.string("Could not create article"))]
        |> json.object
        |> json.to_string_builder,
        420,
      )
    }
  }
}
