# Offset pagination for the web lists. The API has its own envelope; this
# one only feeds the prev/next links.
module Paged
  PER_PAGE = 25

  Pager = Data.define(:page, :pages, :total) do
    def first? = page <= 1

    def last? = page >= pages
  end

  def paginate(scope, per: PER_PAGE)
    page = [ params[:page].to_i, 1 ].max
    total = scope.count
    pages = [ (total.to_f / per).ceil, 1 ].max
    page = [ page, pages ].min
    [ scope.offset((page - 1) * per).limit(per), Pager.new(page: page, pages: pages, total: total) ]
  end
end
