//kindeditor初始化
var editor;
KindEditor.ready(function(K) {
    editor = K.create('.editor', {
        resizeType : 1,
        allowPreviewEmoticons : false,
        allowImageUpload : false,
        items : [
            'fontname', 'fontsize', '|', 'forecolor', 'hilitecolor', 'bold', 'italic', 'underline',
            'removeformat', '|', 'justifyleft', 'justifycenter', 'justifyright', '|', 'image', 'link']
    });
});

jQuery(document).ready(function() {
    jQuery("abbr.timeago").timeago();
    paginate()
});

$("#tabs-profile").click(function () {
    $("#tabs-profile").addClass('active');
    $("#tabs-password").removeClass("active");
    $("#edit-username-desc").css({'display':''});
    $("#edit-user-password").css({'display':'none'})
});

$("#tabs-password").click(function () {
    $("#tabs-profile").removeClass('active');
    $("#tabs-password").addClass("active");
    $("#edit-username-desc").css({'display':'none'});
    $("#edit-user-password").css({'display':''})
});

//上传头像
$('#buttonUpload').click(function () {
    loading();
    $.ajaxFileUpload({
        url :'/users/avatar',
        secureuri :false,
        dataType : 'json',
        fileElementId :'fileToUpload',
        success : function (data, status){
            if (data.msg == 'ok') {
                //d = new Date();
                //$('#thumb48').attr('src','/avatar/thumb/' + data.filename + "?" + d.getTime());
                //$('#medium100').attr('src', '/avatar/medium/' + data.filename + "?" + d.getTime());
                $('#thumb48').removeAttr("src").attr('src','/avatar/thumb/' + data.filename);
                $('#medium100').removeAttr("src").attr('src', '/avatar/medium/' + data.filename);
            } else {
                alert(data.errormsg);
                return false;
            }
        },
        error: function (data, status, e){
            alert(e);
        }
    });
    return false;
});

function loading (){
    $("#loading").ajaxStart(function(){
        $(this).show();
    }).ajaxComplete(function(){
            $(this).hide();
        });
}

//notification
$("a.notifi_read").click(function() {
    var nid   = $(this).attr("data-id");
    var divid = "#notifications-" + nid;
    $.ajax({
        type: "get",
        url: "/notifications/" + nid + "/delete",
        async: false,
        dataType: "json",
        success: function(data) {
            if (data.msg == "ok") {
                $(divid).remove();
                var count = parseInt($("span#notifications-counts").text());
                $("span#notifications-counts").text(count - 1);
            } else {
                alert("删除出错,请稍后再删除!");
            }
        }
    });
    return false;
});
$("a#notifi_read_all").click(function() {
    $.ajax({
        type: "get",
        url: "/notifications/destroy",
        async: false,
        dataType: "json",
        success: function(data) {
            if (data.msg == "ok") {
                $("div#notifications-all").remove();
                $("span#notifications-counts").text(0);
            } else {
                alert("删除出错,请稍后再删除!");
            }
        }
    });
    return false;
});

//删除回复
$('a.comment-del').click(function(){
    var topicid   = $('#topic-comments-all').attr('data');
    var commentid = $(this).attr('data');
    $.ajax({
        type: "put",
        url: "/replies/" + commentid + "/delete",
        async: false,
        data: {"topic_id": topicid},
        dataType: "json",
        success: function(data) {
            if (data.msg == "ok") {
                $("#comment-text-" + commentid).html("<s>该内容已被删除!</s>");
            } else {
                alert("删除回复失败!");
            }
        }
    });
    return false;
});

//回复
function create_comments() {
    if (editor.isEmpty()) {
        alert("回复的内容不能为空!");
        return false;
    }
    $("input.submit").attr('disabled','disabled');
    $.ajax({
        type: "post",
        url: "/replies",
        async: false,
        data: {"topic_id": $("input[name='reply[topic_id]']").val(), "content": editor.html()},
        dataType: "json",
        success: function(data) {
            if (data.msg == "ok") {
                var comment_html = '<div class="comment-item"><div class="icon"><a href="/members/' + data.user.id + '"><img src="/avatar/thumb/' + data.user.avatar + '" alt="' + data.user.username + '" /></a></div><div class="content"><p style=""><a class="to" href="/members/' + data.user.id + '">' + data.user.username + '</a> <span class="comment-time">' + data.reply.created_at + '</span><span class="comment-time" style="float: right;">#' + data.reply.the_where + '</span><span class="comment-time"><a data="' + data.user.username +'" class="go_at to" href="javascript:;">回复</a></span></p><p style="margin-top: 5px; line-height: 23px;"><span class="comment-text">' + data.reply.content +'</span></p></div></div>';
                $('#topic-comments-all').append(comment_html);
                editor.html('');
                $("input.submit").removeAttr("disabled");
            } else {
                alert("no");
            }
        }
    });
}

// @某人 回复
$(".go_at").live("click", function(e) {
    e.preventDefault();
    var append_str = "@" + $(this).attr("data") + "&nbsp;";
    editor.insertHtml(append_str);
});

$(".comment-item").live({
    "mouseover" : function() {
        $(this).find(".go_at").show();
    },

    "mouseout": function() {
        $(this).find(".go_at").hide();
    }

});

//
$(".login_user").hover( function() {
    $(this).toggleClass("active",!$(this).hasClass("active"));
});

//分页
function paginate() {
    var pathname = window.location.pathname;
    var search   = window.location.search;
    var reg      =  /\?page=(\d+)/;
    if (pathname == "/topics" || pathname == "/topics/newest" || /topics\/tag\/\S/.test(pathname) || /nodes\/\d+/.test(pathname)) {
        if(reg.test(search)) {
            var page      = reg.exec(search)[1];
            var next_page = parseInt(page) + 1;
            $('a.page_item').attr("href",pathname + "?page=" + next_page);
        } else {
            $('a.page_item').attr("href",pathname + "?page=1");
        }
    }
}

// 发表主题简单验证下
function topic_validate() {
    var title = $("input[name='topics[title]']").val();
    var node  = $("select[name='topics[node]']").val();
    var tags  = $("input[name='topics[tags]']").val();
    if(title.length == 0) {
        alert('主题的标题不能为空');
        return false;
    } else if(node == '选择分类') {
        alert('请选择分类');
        return false;
    } else if(editor.isEmpty()) {
        alert('主题内容不能为空');
        return false
    } else if(tags.length == 0) {
        alert('标签不能为空');
        return false;
    }
    return true;
}

var register = {
    checkFlag : true,//检查是否通过
    checkUserRegisterOneFocus:function(id){
        if(id=="email"){
            register.email();
        }else if(id=="password"){
            register.password();
        }else if(id=="repassword"){
            register.repassword();
        }else if(id=="username") {
            register.username();
        }
    },
    checkEmail:function(){
        var email = $('#email').val();
        $.ajax({
            type: "post",
            url: "/api/check_email",
            async: false,
            data: {"email": email},
            dataType: "json",
            success: function(data) {
                if (data.msg == "ok") {
                    register.checkFlag = false;
                    $('#emailerror').html("<i><em></em>该邮箱地址已被注册</i>").show();
                } else {
                    $('#emailerror').html("<i><em id='right'></em>该邮箱地址可以注册</i>").show();
                }
            }
        });
    },
    removeerrorInfo : function(id) {
        var errorid = id + "error";
        $('#' + errorid + '').html("").hide();
    },
    unDiv:function(val){
        $("#show"+val).css('display','none');
    },
    showDiv:function(val){
        $("#show"+val).css('display','');
    },
    submitUserRegisterOne: function() {
        register.email();
        register.password();
        register.repassword();
        register.username();
        if (register.checkFlag) {
            return true;
        } else {
            return false;
        }
    },
    email: function() {
        var email = $('#email').val();
        if (email == '' || email == null) {
            register.checkFlag = false;
            $('#emailerror').html("<i><em></em>请输入Email地址</i>").show();
        } else {
            if (/^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/.test(email) == false) {
                register.checkFlag = false;
                $('#emailerror').html("<i><em></em>请输入正确的邮箱地址</i>").show();
            } else {
                register.checkEmail();
            }
        }
    },
    password: function() {
        var password = $('#password').val();
        if (password == "" || password == null) {
            register.checkFlag = false;
            $('#passworderror').html("<i><em></em>请输入密码</i>").show();
        }else if(password.length<6) {
            register.checkFlag = false;
            $('#passworderror').html("<i><em></em>请输入6-16位长度的密码</i>").show();
        }else {
            $('#passworderror').html("&nbsp;").hide();
        }
    },
    repassword: function() {
        var repassword = $('#repassword').val();
        if(repassword!=$('#password').val()){
            register.checkFlag = false;
            $('#resPassword2error').html("<i><em></em>密码和确认密码输入不一致</i>").show();
        }else {
            $('#resPassword2error').html("&nbsp;").hide();
        }
    },
    username: function() {
        var username = $('#username').val();
        if (username == "" || username == null) {
            register.checkFlag = false;
            $('#usernameerror').html("<i><em></em>请输入用户名</i>").show();
        }else if(/^[\u4E00-\u9FA5\uf900-\ufa2d\w]{3,20}$/.test(username) == false) {
            register.checkFlag = false;
            $('#usernameerror').html("<i><em></em>用户名不合法</i>").show();
        }else {
            $('#usernameerror').html("&nbsp;").hide();
        }
    },

    update_username_desc: function() {
        register.username();
        if (register.checkFlag) {
            $(".btn").attr('disabled','disabled');
            $.ajax({
                type: "post",
                url: "/users/profile",
                async: false,
                data: {"username": $('#username').val(), "description": $('#user-desc').val()},
                dataType: "json",
                success: function(data) {
                    if (data.msg == "ok") {
                        alert("修改成功!");
                    } else {
                        alert("修改失败,请检查用户名是否正确!");
                    }
                }
            });
        }
        $(".btn").removeAttr("disabled");
        return true;
    },

    update_user_pwd: function() {
        var old_pwd = $('#old-pwd').val();
        if (old_pwd == "" || old_pwd == null) {
            register.checkFlag = false;
            $('#old-pwd-error').html("<i><em></em>请输入旧密码</i>").show();
        }else {
            $('#old-pwd-error').html("&nbsp;").hide();
        }
        register.password();
        register.repassword();

        if (register.checkFlag) {
            $(".btn").attr('disabled','disabled');
            $.ajax({
                type: "post",
                url: "/users/password",
                async: false,
                data: {"old_pwd": $('#old-pwd').val(), "new_pwd": $('#password').val(), "re_pwd": $('#repassword').val()},
                dataType: "json",
                success: function(data) {
                    if (data.msg == "ok") {
                        alert("密码修改成功!");
                    } else {
                        alert("密码修改失败,请检查原密码是否正确!");
                    }
                }
            });
        }
        $(".btn").removeAttr("disabled");
        return true;
    }
};

