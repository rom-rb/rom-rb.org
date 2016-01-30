export default function activateNavigationToggler() {
  const toggler = document.getElementById('navigation__toggler');
  toggler.addEventListener('click', navigationToggler);
}

function navigationToggler() {
  const toggler = document.getElementById('navigation__toggler');
  const items = document.getElementById('navigation__items');

  if (items.className.match(/--is-active$/)) {
    toggler.className = 'header__menu-toggler';
    items.className = 'header__menu';
  } else {
    toggler.className = 'header__menu-toggler--is-active';
    items.className = 'header__menu--is-active';
  }
}
