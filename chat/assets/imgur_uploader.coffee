class window.ImgurUploader
  @init: (imgurClientId, @alertHelper) =>
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
        @alertHelper.newAlert("alert-info", "Uploading image...")
        $.ajax("https://api.imgur.com/3/image",
          {
            type:'POST',
            headers: { 'Authorization': 'Client-ID ' + @imgurClientId },
            data: fd,
            processData: false,
            crossDomain: true,
            contentType : false,
            success: (resp, textStatus, jqXHR) =>
              Util.insertTextAtCursor($("#chat-text")[0], '!['+file.name+']('+resp.data.link+')')
              @alertHelper.delAlert()
            error: (jqXHR, textStatus, errorThrown) =>
              @alertHelper.timedAlert("alert-error", "Image upload failed: " + errorThrown, 2000)
          }
        )
