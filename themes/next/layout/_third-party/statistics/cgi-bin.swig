{%- if theme.cgi_visitors.enable%}
<script{{ pjax }}>
  (function() {
      function addCount()
      {
        var counter_span = document.getElementsByClassName("cgi_visitors");
        const Url = "{{theme.cgi_visitors.url}}"
        const Http = new XMLHttpRequest();
        Http.open("POST", Url, true);
        Http.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
		    Http.send("url=" + counter_span[0].id);
        Http.onreadystatechange=(e)=>{
          console.log(Http.responseText)
          counter_span[0].getElementsByClassName("cgi-visitors-count")[0].innerHTML=Http.responseText;
          if(Http.readyState === 4 && Http.status === 200){
            console.log(Http.responseText);
            counter_span[0].getElementsByClassName("cgi-visitors-count")[0].innerHTML=Http.responseText;
          }
        }
 
      }

      function getTime(c)
      {
        const counter = c;
        const Http = new XMLHttpRequest();
        const Url = "{{theme.cgi_visitors.url}}?url=" + counter.id
        Http.open("GET", Url);
        Http.send();
        Http.onreadystatechange=(e)=>{
          if(Http.readyState === 4 && Http.status === 200){
            counter.getElementsByClassName("cgi-visitors-count")[0].innerHTML=Http.responseText;
          }

        }
      }
      function showTime()
      {
        const counter_spans = document.getElementsByClassName("cgi_visitors");
        for(var i=0; i < counter_spans.length; i++)
        {
          getTime(counter_spans[i]);
        }
        
      }

      if (CONFIG.page.isPost)
      {
        if (CONFIG.hostname !== location.hostname) return;
            addCount();
      } else if (document.querySelectorAll('.post-title-link').length >= 1) {
            showTime();
      }
    


  }
    )();
</script>

{%- endif %}
