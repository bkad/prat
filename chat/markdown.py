from misaka import (Markdown, HtmlRenderer, EXT_NO_INTRA_EMPHASIS, EXT_AUTOLINK, EXT_TABLES, EXT_FENCED_CODE,
    EXT_STRIKETHROUGH, EXT_LAX_HTML_BLOCKS, EXT_SPACE_HEADERS, HTML_HARD_WRAP, HTML_SKIP_HTML,
    HTML_NEW_TAB_LINKS)
import pygments
from pygments.lexers import get_lexer_by_name
from pygments.formatters import HtmlFormatter
from pygments.util import ClassNotFound

class HtmlPygmentsRenderer(HtmlRenderer):
  def block_code(self, code, language):
    language = language or "text"
    lexer_options = { "encoding": "utf-8", "stripnl": False, "stripall": False }
    try:
      lexer = get_lexer_by_name(language, **lexer_options)
    except ClassNotFound as exception:
      lexer = get_lexer_by_name("text", **lexer_options)
    formatter = HtmlFormatter(nowrap=True)
    rendered_code = pygments.highlight(code, lexer, formatter)
    return "<div class=\"highlight\">{0}</div>".format(rendered_code)

pygments_renderer = HtmlPygmentsRenderer(HTML_HARD_WRAP | HTML_SKIP_HTML | HTML_NEW_TAB_LINKS)
markdown_renderer = Markdown(pygments_renderer, EXT_NO_INTRA_EMPHASIS | EXT_AUTOLINK | EXT_TABLES | EXT_FENCED_CODE |
    EXT_STRIKETHROUGH | EXT_LAX_HTML_BLOCKS | EXT_SPACE_HEADERS)

def render(input_string):
  return markdown_renderer.render(input_string)
