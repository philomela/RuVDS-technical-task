var onRemovedServers = new Set();
var serversOnDelete = new Array();

$(".btn-add").click(function () {
    $.ajax({
        url: "/Home/AddServer",
        Method: "GET",
        success: function () {
            location.reload();
        }
    });
});

$(".onRemoved").click(function () {
    if (($(this).parent().children(".remove-datetime").text() == "") && ($(this).text() == "")) {
        $(this).css("background-color", "rgb(174, 213, 245)");
        $(this).text("X");
        onRemovedServers.add({ nameServer: $(this).parent().attr("id"), idServer: $(this).parent().children(".server-id").text() });
    }
    else if (($(this).parent().children(".remove-datetime").text() == "") && ($(this).text() == "X")) {
        $(this).css("background-color", "rgb(234, 240, 245)");
        $(this).text("");
        onRemovedServers.forEach(current => { current.nameServer == ($(this).parent().attr("id")) ? onRemovedServers.delete(current) : null });
    }


});

$(".btn-remove").click(function () {
    serversOnDelete = Array.from(onRemovedServers);
    $.ajax({
        url: "/Home/RemoveServers/",
        Method: "POST",
        data: "jsonOnRemoveServers=" + JSON.stringify(serversOnDelete),
        contentType: "application/json;charset=utf-8",
        success: function () {
            location.reload();
        }
    });
});

$(".btn-del").click(function () {
    $.ajax({
        url: "/Home/DeleteAllServers/",
        Method: "GET",
        success: function () {
            location.reload();
        }
    });
});