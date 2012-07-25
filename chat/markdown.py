from misaka import (Markdown, HtmlRenderer, EXT_NO_INTRA_EMPHASIS, EXT_AUTOLINK, EXT_TABLES, EXT_FENCED_CODE,
    EXT_STRIKETHROUGH, EXT_LAX_HTML_BLOCKS, EXT_SPACE_HEADERS, HTML_HARD_WRAP)
import pygments
from pygments.lexers import get_lexer_by_name
from pygments.formatters import HtmlFormatter
import cgi

def unescape(input_string):
  return input_string.replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&")

class HtmlPygmentsRenderer(HtmlRenderer):
  def block_code(self, code, language):
    language = language or "text"
    lexer = get_lexer_by_name(language, encoding="utf-8", stripnl=False, stripall=False)
    formatter = HtmlFormatter(nowrap=True)
    unescaped_code = unescape(code)
    rendered_code = pygments.highlight(unescaped_code, lexer, formatter)
    return "<div class=\"highlight\">{0}</div>".format(rendered_code)

  def codespan(self, code):
    unescaped_code = unescape(code)
    return "<code>{0}</code>".format(unescaped_code)

pygments_renderer = HtmlPygmentsRenderer(HTML_HARD_WRAP)
markdown_renderer = Markdown(pygments_renderer, EXT_NO_INTRA_EMPHASIS | EXT_AUTOLINK | EXT_TABLES | EXT_FENCED_CODE |
    EXT_STRIKETHROUGH | EXT_LAX_HTML_BLOCKS | EXT_SPACE_HEADERS)

def render(input_string):
  escaped_input = cgi.escape(input_string)
  return markdown_renderer.render(escaped_input)
