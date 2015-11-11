# Websocket communication protocol for ISK
ISK uses websockets to communicate between the server and various clients. This is used to update the html views for users and the presentation data on displays.

## Endpoints
There are two kinds of websocket endpoints, one for the interface between the server and slideshow displays and another for users.

### Display interface
The display interface is located at url /displays/:id/websocket where :id is the numeric id of the display. This connection will send updated display serializations as needed, receives updates from the display and handles the communication between the display remote control view and the display.

### General notification interface
The second websocket endpoint is at /websocket/general and it is used for updating all html views for users when the various objects are updated.

#### Message format
The messages are json serialized arrays. Their content is as follows:

```JSON
[
	"object",
	12,
	{"key":1}
]
```

Where first element "object" is the class of object that this message is about and it is one of the following:
* display
* display_state
* group
* master_group
* override_queue
* presentation
* slide
* ticket

The next element is the numeric id of the object. Last field is a list of the changed attributes and their new values as a hash.