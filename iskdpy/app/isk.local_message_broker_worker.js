all_ports=[]

onconnect = function(e) {
    console.log(e)
    var my_port = e.ports[0];
    all_ports.push(my_port);

    my_port.onmessage = function(e) {
      console.log(e)
      all_ports.forEach( function(port) {
        port.postMessage(e.data);
      });
    }

    port.start();
}

