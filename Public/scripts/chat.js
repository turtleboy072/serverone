function Chat(host) {
    var chat = this;
    var myImage = document.getElementById('image');
    chat.ws = new WebSocket('wss://' + host);
    chat.ws.onopen = function() {
         console.log("on open");
    };
    chat.ws.onclose = function() {
        console.log("on close");
    };
    chat.ws.onerror = function() {
        console.log("on error");
    };
    chat.imageCache = {};
    chat.ws.onmessage = function(event) {
        var received_msg = event.data;
        var reader = new FileReader();
        reader.readAsDataURL(received_msg);
        reader.onloadend = function() {
            base64data = reader.result;
            myImage.src = base64data;
           
        }
        
    }

    
};
