Messages in Prat are written in a [Markdown](http://daringfireball.net/projects/markdown/syntax) variant similar to [Github-formatted markdown](http://github.github.com/github-flavored-markdown/). There are a couple of features that help when entering complex markup into Prat:

* Hitting `shift+enter` enters a newline instead of sending the message
* You can hit the Preview button to see how a message will be rendered before sending it.

Below you can see some of the more useful markup features that are available in Prat:

## Text formatting

    Text can be **bold** or *italic* (_this_ is also italic).

Text can be **bold** or *italic* (_this_ is also italic).

## Usernames and channels

You can address someone directly in a message by typing `@username` -- this is displayed as @username. You can use tab completion to help you write the username quickly. A message addressed at you will have your username highlighted in blue, and will alert you with a pinging sound.

Channel links are written as `#roller-coasters`: #roller-coasters. This will be a link that takes you to that channel.

## Links and images

URLs are turned into links automatically: http://google.com. You can make other links using the syntax `[link text](http://google.com)`: [link text](http://google.com).

Inline images take the syntax `![link text](/static/images/nyan.gif)`:

![link text](/static/images/nyan.gif)

## Quotes

    > You can make block quotes by prefixing with '>'
    >
    > -- me

> You can make block quotes by prefixing with '>'
>
> -- me

## Code

    Inline code can be made with backticks, `like this`.

Inline code can be made with backticks, `like this`.

Code blocks are formed by indenting text by four or more spaces from the surrounding text, or by surrounding the block with three or more backticks:

      def answer():
        return 42

    ```
    def answer():
      return 42
    ```

These both render as:

    def answer():
      return 42

The second form also allows you to specify a language and have syntax highlighting:

    ``` go
    func answer() int {
      return 42
    }
    ```

is rendered as:

``` go
func answer() int {
  return 42
}
```
