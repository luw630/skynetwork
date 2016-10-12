function getCookie(name) {
    var r = document.cookie.match("\\b" + name + "=([^;]*)\\b");
    return r ? r[1] : undefined;
}

function tip(message)
{
    BootstrapDialog.show({
        type:BootstrapDialog.TYPE_SUCCESS,
        title:"提示",
        message: message,
        buttons: [{
            label: '了解',
            action: function(dialogItself){
                dialogItself.close();
            }
        }]
    });
}

function AJAX(url, callback)
{
    $.ajax({
        url: url,
        type: "post",
        async: true,
        data: {
        },
        dataType: "json",
        error: function() {
            BootstrapDialog.show({
                type:BootstrapDialog.TYPE_DANGER,
                title:"错误",
                message: '服务器连接失败！',
                buttons: [{
                    label: '了解',
                    action: function(dialogItself){
                        dialogItself.close();
                    }
                }]
            });
        },
        success: function(response) {
            if (!response.success)
            {
                BootstrapDialog.show({
                    type:BootstrapDialog.TYPE_WARNING,
                    title:"警告",
                    message: response.message,
                    buttons: [{
                        label: '了解',
                        action: function(dialogItself){
                            dialogItself.close();
                        }
                    }]
                });
            }
            else
            {
                callback(response.data)
            }
        }
    });
}

$(document).ready(function() {
    $('form,input,select,textarea').attr("autocomplete", "off");

    // $.ajaxSetup({
    //     beforeSend: function(xhr, settings) {
    //         xhr.setRequestHeader("X-XSRFToken", getCookie("_xsrf"));
    //     }
    // });
});