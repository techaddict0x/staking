var lastId,
topMenu = $("nav.onepage, .footer-menu.onepage"),
topMenuHeight = $("header").height();
menuItems = topMenu.find("a"),
scrollItems = menuItems.map(function(){
});

menuItems.click(function(e){
  var href = $(this).attr("href"),
  offsetTop = href === "#" ? 0 : $(href).offset().top-topMenuHeight+1;
  $('html, body').stop().animate({
    scrollTop: offsetTop
}, 900);
  e.preventDefault();
});

$(window).scroll(function(){
   var fromTop = $(this).scrollTop()+topMenuHeight;
   var cur = scrollItems.map(function(){
   if ($(this).offset().top < fromTop)
         return this;
 });
   cur = cur[cur.length-1];
   var id = cur && cur.length ? cur[0].id : "";

   if (lastId !== id) {
       lastId = $();
       menuItems
       .parent().removeClass("active")
       .end().filter("[href=#"+id+"]").parent().addClass("active");
   }

   //  if($(window).scrollTop() + $(window).height() > $(document).height() - 1) {
   //     $("nav li").removeClass("active");
   //     $("nav li:last").addClass("active");
   // }

  $(window).scroll(function(){
   if($(window).scrollTop() > topMenuHeight){
     $("header").addClass('fixed');
    }else{
     $("header").removeClass('fixed');
 }
});

});