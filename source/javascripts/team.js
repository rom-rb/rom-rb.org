var RomRb = {
  renderTeam: function() {
    var $team = $('#team');
    var $template = $('#template').html();

    $.getJSON('https://api.github.com/orgs/rom-rb/public_members', function(response) {
      for (var i=0; i < response.length; i++) {
        var member = response[i];

        template = $template.replace('href', "href='" + member.html_url + "'");
        template = template.replace('src', "src='" + member.avatar_url + "'");
        template = template.replace('NAME', member.login);

        $team.append(template);
      }
    });
  }
}
