class window.ImgurUploader
  @init: (imgurClientId) =>
    @imgurClientId = imgurClientId
    @initImageUpload()

  @initImageUpload: () =>
      $('#chat-text').on('dragover', (e) =>
        console.log("DRAGOVER")
        e.preventDefault()
        false
      )
      $('#chat-text').on('drop', @handleDrop)

  @handleDrop: (event) =>
    event.stopPropagation();
    event.preventDefault();

    # Fixes issue with chrome on ubuntu 12.XX
    dataTransfer = event.dataTransfer || event.originalEvent.dataTransfer
    files = dataTransfer.files

    for file in files
      if file.type.match(/image.*/)
        fd = new FormData()
        fd.append("image", file)
        $.ajax("https://api.imgur.com/3/image",
          {
            type:'POST',
            headers: { 'Authorization': 'Client-ID ' + @imgurClientId },
            error: @onError,
            data: fd,
            processData: false,
            crossDomain: true,
            contentType : false,
            success: (resp, textStatus, jqXHR) =>
              Util.insertTextAtCursor($("#chat-text")[0], '!['+file.name+']('+resp.data.link+')')
          }
        )

  @onError: (jqXHR, textStatus, errorThrown) =>
    console.log(textStatus)
    console.log(errorThrown)
