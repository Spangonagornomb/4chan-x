ImageHover =
  init: ->
    return if g.VIEW is 'catalog'
    if Conf['Image Hover']
      Post.callbacks.push
        name: 'Image Hover'
        cb:   @node
    if Conf['Image Hover in Catalog']
      CatalogThread.callbacks.push
        name: 'Catalog Image Hover'
        cb:   @catalogNode
  node: ->
    return unless @file and (@file.isImage or @file.isVideo)
    $.on @file.thumb, 'mouseover', ImageHover.mouseover @
  catalogNode: ->
    {file} = @thread.OP
    return unless file and (file.isImage or file.isVideo)
    $.on @nodes.thumb, 'mouseover', ImageHover.mouseover @thread.OP
  mouseover: (post) -> (e) ->
    return unless doc.contains @
    {file} = post
    {isVideo} = file
    return if file.isExpanding or file.isExpanded
    file.isHovered = true
    error = ImageHover.error post
    if ImageCommon.cache?.dataset.fullID is post.fullID
      el = ImageCommon.popCache()
      $.on el, 'error', error
      $.queueTask(-> el.src = el.src) if /\.gif$/.test el.src
      el.currentTime = 0 if isVideo and el.readyState >= el.HAVE_METADATA
    else
      el = $.el (if isVideo then 'video' else 'img')
      el.dataset.fullID = post.fullID
      $.on el, 'error', error
      el.src = file.URL
    el.id = 'ihover'
    $.after Header.hover, el
    if isVideo
      el.loop     = true
      el.controls = false
      el.play() if Conf['Autoplay']
    [width, height] = file.dimensions.split('x').map (x) -> +x
    {left, right} = @getBoundingClientRect()
    padding = 16
    maxWidth = Math.max left, doc.clientWidth - right
    maxHeight = doc.clientHeight - padding
    scale = Math.min 1, maxWidth / width, maxHeight / height
    el.style.maxWidth = "#{scale * width}px"
    el.style.maxHeight = "#{scale * height}px"
    UI.hover
      root: @
      el: el
      latestEvent: e
      endEvents: 'mouseout click'
      asapTest: -> true
      height: scale * height + padding
      noRemove: true
      cb: ->
        if isVideo
          el.pause()
        $.rm el
        $.off el, 'error', error
        el.removeAttribute 'id'
        el.removeAttribute 'style'
        ImageCommon.pushCache el
        $.queueTask -> delete file.isHovered
  error: (post) -> ->
    return if ImageCommon.decodeError @, post
    ImageCommon.error @, post, 3 * $.SECOND, (URL) =>
      if URL
        @src = URL + if @src is URL then '?' + Date.now() else ''
      else
        $.rm @
