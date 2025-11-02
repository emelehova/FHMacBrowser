import Foundation

enum Scripts {
    static let killAnimationsCSS = """
    * { animation: none !important; transition: none !important; scroll-behavior: auto !important; }
    html, body { scroll-behavior: auto !important; }
    """

    static let throttleRAFJS = """
    (function(){
      const fps = 30;
      const interval = 1000/fps;
      let last = 0;
      const _raf = window.requestAnimationFrame;
      window.requestAnimationFrame = function(cb){
        return _raf(function(ts){
          if (ts - last >= interval) { last = ts; cb(ts); }
          else { _raf(cb); }
        });
      };
    })();
    """

    static let lazyMediaJS = """
    (function(){
      document.addEventListener('DOMContentLoaded', function(){
        document.querySelectorAll('img:not([loading])').forEach(img => img.setAttribute('loading','lazy'));
        document.querySelectorAll('iframe:not([loading])').forEach(f => f.setAttribute('loading','lazy'));
        document.querySelectorAll('video').forEach(v => { v.preload='metadata'; });
        document.querySelectorAll('audio').forEach(a => { a.preload='none'; });
      });
    })();
    """

    static func webSocketBatchJS(ms: Int) -> String {
        return """
        (function(){
          const delay = \(ms);
          const open = WebSocket.prototype.addEventListener;
          WebSocket.prototype.addEventListener = function(type, listener, options){
            if (type !== 'message') return open.call(this, type, listener, options);
            let queue = [];
            let scheduled = false;
            open.call(this, 'message', (ev)=>{
              queue.push(ev);
              if (!scheduled){
                scheduled = true;
                setTimeout(()=>{
                  const combined = new MessageEvent('message', { data: JSON.stringify(queue.map(e=>e.data)) });
                  listener(combined);
                  queue = []; scheduled = false;
                }, delay);
              }
            }, options);
          };
        })();
        """
    }

    static func mobileMetaViewportJS() -> String {
        return """
        (function(){
           var tag = document.querySelector('meta[name=viewport]');
           if(!tag){
             tag = document.createElement('meta');
             tag.name = 'viewport';
             document.head.appendChild(tag);
           }
           tag.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0';
        })();
        """
    }
}
