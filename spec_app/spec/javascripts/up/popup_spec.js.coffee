describe 'up.popup', ->

  u = up.util

  describe 'Javascript functions', ->

    describe 'up.popup.attach', ->

      it 'does not explode if the popup was closed before the response was received', ->
        $span = affix('span')
        up.popup.attach($span, url: '/foo', target: '.container')
        up.popup.close()
        respond = => @respondWith('<div class="container">text</div>')
        expect(respond).not.toThrowError()
        expect($('.up-error')).not.toExist()

    describe 'up.popup.coveredUrl', ->

      it 'returns the URL behind the popup', (done) ->
        up.history.replace('/foo')
        expect(up.popup.coveredUrl()).toBeUndefined()

        $popupLink = affix('a[href="/bar"][up-popup=".container"]')
        $popupLink.click()
        @respondWith('<div class="container">text</div>')
        expect(up.popup.coveredUrl()).toEndWith('/foo')
        up.popup.close().then ->
          expect(up.popup.coveredUrl()).toBeUndefined()
          done()

    describe 'up.popup.close', ->

      it 'should have tests'

    describe 'up.popup.source', ->

      it 'should have tests'

  describe 'unobtrusive behavior', ->

    describe 'a[up-popup]', ->

      it "loads this link's destination in a popup when clicked", ->
        $link = affix('a[href="/path/to"][up-popup=".middle"]').text('link')
        $link.css
          position: 'fixed'
          left: '100px'
          top: '50px'
        $link.click()
        expect(@lastRequest().url).toMatch /\/path\/to$/
        @respondWith """
          <div class="before">new-before</div>
          <div class="middle">new-middle</div>
          <div class="after">new-after</div>
          """

        $popup = $('.up-popup')

        expect($popup).toExist()
        expect($popup.find('.middle')).toHaveText('new-middle')
        expect($popup.find('.before')).not.toExist()
        expect($popup.find('.after')).not.toExist()

        popupDims = u.measure($popup, full: true)
        linkDims = u.measure($link, full: true)

        expect(popupDims.right).toBeAround(linkDims.right, 1)
        expect(popupDims.top).toBeAround(linkDims.top + linkDims.height, 1)

    describe '[up-close]', ->

      describe 'when clicked inside a popup', ->

        it 'closes the open popup and prevents the default action', ->
          $popup = affix('.up-popup')
          $link = $popup.affix('a[up-close]') # link is within the popup
          up.hello($link)
          wasDefaultPrevented = false
          wasClosed = false
          up.on 'click', 'a[up-close]', (event) ->
            wasDefaultPrevented = event.isDefaultPrevented()
            true # the line above might return false and cancel propagation / prevent default
          up.on 'up:popup:close', ->
            wasClosed = true
          $link.click()
          expect(wasClosed).toBe(true)
          expect(wasDefaultPrevented).toBe(true)

      describe 'when no popup is open', ->

        it 'does neither close the popup nor prevent the default action', ->
          $link = affix('a[up-close]') # link is outside the popup
          up.hello($link)
          wasDefaultPrevented = false
          wasClosed = false
          up.on 'click', 'a[up-close]', (event) ->
            wasDefaultPrevented = event.isDefaultPrevented()
            true # the line above might return false and cancel propagation / prevent default
          up.on 'up:popup:close', ->
            wasClosed = true
          $link.click()
          expect(wasClosed).toBe(false)
          expect(wasDefaultPrevented).toBe(false)

    describe 'when replacing content', ->

      beforeEach ->
        up.motion.config.enabled = false

      it 'prefers to replace a selector within the popup', ->
        $outside = affix('.foo').text('old outside')
        $link = affix('.link')
        up.popup.attach($link, href: '/path', target: '.foo')
        @respondWith("<div class='foo'>old inside</div>")
        up.flow.implant('.foo', "<div class='foo'>new text</div>")
        expect($outside).toBeInDOM()
        expect($outside).toHaveText('old outside')
        expect($('.up-popup')).toHaveText('new text')

      it 'auto-closes the popup when a replacement from inside the popup affects a selector behind the popup', ->
        affix('.outside').text('old outside')
        $link = affix('.link')
        up.popup.attach($link, href: '/path', target: '.inside')
        @respondWith("<div class='inside'>old inside</div>")
        up.flow.implant('.outside', "<div class='outside'>new outside</div>", origin: $('.inside'))
        expect($('.outside')).toHaveText('new outside')
        expect($('.up-popup')).not.toExist()

      it 'does not auto-close the popup when a replacement from inside the popup affects a selector inside the popup', ->
        affix('.outside').text('old outside')
        $link = affix('.link')
        up.popup.attach($link, href: '/path', target: '.inside')
        @respondWith("<div class='inside'>old inside</div>")
        up.flow.implant('.inside', "<div class='inside'>new inside</div>", origin: $('.inside'))
        expect($('.inside')).toHaveText('new inside')
        expect($('.up-popup')).toExist()

      it 'does not auto-close the popup when a replacement from outside the popup affects a selector outside the popup', ->
        affix('.outside').text('old outside')
        $link = affix('.link')
        up.popup.attach($link, href: '/path', target: '.inside')
        @respondWith("<div class='inside'>old inside</div>")
        up.flow.implant('.outside', "<div class='outside'>new outside</div>", origin: $('.outside'))
        expect($('.outside')).toHaveText('new outside')
        expect($('.up-popup')).toExist()

      it 'does not auto-close the popup when a replacement from outside the popup affects a selector inside the popup', ->
        affix('.outside').text('old outside')
        $link = affix('.link')
        up.popup.attach($link, href: '/path', target: '.inside')
        @respondWith("<div class='inside'>old inside</div>")
        up.flow.implant('.inside', "<div class='inside'>new inside</div>", origin: $('.outside'))
        expect($('.inside')).toHaveText('new inside')
        expect($('.up-popup')).toExist()
