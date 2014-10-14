<?php

$whitelist = array(
  '127.0.0.1',
  '::1'
);

if (in_array($_SERVER['REMOTE_ADDR'], $whitelist) && $_GET['token'] == 'eVooqueungoo9bee0zujaequ7ochaoja') {
  if (function_exists('opcache_reset')) {
    opcache_reset();
    echo "success\n";
    exit;
  }
}

echo "error\n";
