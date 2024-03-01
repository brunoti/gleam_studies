import sqlight.{type Connection}
import gleam/json.{type Json}
import gleam/result.{try}
import gleam/list
import gleam/io
import gleam/pair
import gleam/function.{tap}
import gleam/dynamic.{type Dynamic}

pub type Article {
  Article(
    id: Int,
    title: String,
    content: String,
    created_at: String,
    updated_at: String,
  )
}

pub type ArticleCreateData {
  ArticleCreateData(title: String, content: String)
}

pub type ArticleError {
  ArticleNotFoundError
  ArticleUnknownError(String)
  ArticleDecodeError(String)
}

pub fn all(conn: Connection) -> Result(List(Article), ArticleError) {
  sqlight.query(
    "select * from articles",
    on: conn,
    with: [],
    expecting: decoder(),
  )
	|> tap(fn(result) { io.debug(result) })
  |> result.map_error(fn(error) { ArticleUnknownError(error.message) })
}

pub fn create(
  conn: Connection,
  article: ArticleCreateData,
) -> Result(Int, ArticleError) {
  let query =
    "insert into articles (title, content) values ('"
    <> article.title
    <> "', '"
    <> article.content
    <> "')"

  io.debug(query)

  sqlight.exec(query, conn)
  |> result.map_error(fn(error) { ArticleUnknownError("INSERT: "<> error.message) })
  |> result.then(fn(_) {
    sqlight.query(
      "select last_insert_rowid()",
      on: conn,
      with: [],
      expecting: dynamic.element(0, dynamic.int),
    )
    |> result.map_error(fn(error) { ArticleUnknownError("ID: " <> error.message) })
  })
  |> result.then(fn(id) {
		io.debug(id)
    list.first(id)
    |> result.map_error(fn(_) {
      ArticleUnknownError("Could not get last_insert_rowid")
    })
  })
}

pub fn find_by_id(conn: Connection, id: Int) -> Result(Article, ArticleError) {
  sqlight.query(
    "select * from articles where id = ?",
    on: conn,
    with: [sqlight.int(id)],
    expecting: decoder(),
  )
  |> result.map_error(fn(error) { ArticleUnknownError(error.message) })
  |> result.then(fn(rows) {
    list.first(rows)
    |> result.map_error(fn(_) { ArticleNotFoundError })
  })
}

pub fn decoder() {
  dynamic.decode5(
    Article,
    dynamic.element(0, dynamic.int),
    dynamic.element(1, dynamic.string),
    dynamic.element(2, dynamic.string),
    dynamic.element(3, dynamic.string),
    dynamic.element(4, dynamic.string),
  )
}

pub fn create_data_decoder() {
  dynamic.decode2(
    ArticleCreateData,
    dynamic.field("title", dynamic.string),
    dynamic.field("content", dynamic.string),
  )
}

pub fn to_json(article: Article) -> Json {
  [
    #("id", json.int(article.id)),
    #("title", json.string(article.title)),
    #("content", json.string(article.content)),
    #("created_at", json.string(article.created_at)),
    #("updated_at", json.string(article.updated_at)),
  ]
  |> json.object
}

pub fn from_json(json: Dynamic) -> Result(Article, ArticleError) {
  let my_decoder = decoder()
  my_decoder(json)
  |> result.map_error(fn(_) { ArticleDecodeError("Could not decode article") })
}

pub fn create_data_from_json(
  json: Dynamic,
) -> Result(ArticleCreateData, ArticleError) {
  let my_decoder = create_data_decoder()
  my_decoder(json)
  |> result.map_error(fn(a) {
    io.debug(a)
    ArticleDecodeError("Could not decode article")
  })
}
