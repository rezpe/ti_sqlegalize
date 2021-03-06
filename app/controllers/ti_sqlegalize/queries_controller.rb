require 'sqliterate'
require 'resque'

module TiSqlegalize
  class QueriesController < TiSqlegalize::ApplicationController
    ensure_signed_in

    def create
      query = params['queries']
      return invalid_params unless query && query.is_a?(Hash)
      sql = query['sql']
      return invalid_params unless sql && sql.is_a?(String)
      ast = SQLiterate::QueryParser.new.parse sql
      return invalid_params unless ast

      query = Query.new sql
      query.create!
      query.enqueue!

      href = query_url(query.id)
      rep = {
        queries: {
          id: query.id,
          href: href,
          sql: sql,
          tables: ast.tables
        }
      }
      response.headers['Location'] = href
      render_api json: rep, status: 201
    end

    def show
      id = params[:id]
      offset = [params[:offset].to_i, 0].max
      limit = [[params[:limit].to_i, 1].max, 10000].min

      query = Query.find(id)
      if query
        rep = {
          queries: {
            id: id,
            href: query_url(id),
            status: query.status,
            offset: offset,
            limit: limit,
            quota: query.quota,
            count: query.count,
            schema: query.schema,
            rows: query[offset, limit]
          }
        }
        render_api json: rep, status: 200
      else
        render_api json: {}, status: 404
      end
    end
  end
end
