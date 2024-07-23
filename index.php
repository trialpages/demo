<?php
session_start();

$allowed_ips_file = 'allowed_ips.json';

function get_client_ip() {
    $ipaddress = '';
    if (getenv('HTTP_CLIENT_IP'))
        $ipaddress = getenv('HTTP_CLIENT_IP');
    else if(getenv('HTTP_X_FORWARDED_FOR'))
        $ipaddress = getenv('HTTP_X_FORWARDED_FOR');
    else if(getenv('HTTP_X_FORWARDED'))
        $ipaddress = getenv('HTTP_X_FORWARDED');
    else if(getenv('HTTP_FORWARDED_FOR'))
        $ipaddress = getenv('HTTP_FORWARDED_FOR');
    else if(getenv('HTTP_FORWARDED'))
        $ipaddress = getenv('HTTP_FORWARDED');
    else if(getenv('REMOTE_ADDR'))
        $ipaddress = getenv('REMOTE_ADDR');
    else
        $ipaddress = 'UNKNOWN';
    return $ipaddress;
}

$client_ip = get_client_ip();

if (!file_exists($allowed_ips_file)) {
    file_put_contents($allowed_ips_file, json_encode([]));
}

$allowed_ips = json_decode(file_get_contents($allowed_ips_file), true);

if (count($allowed_ips) < 2 && !in_array($client_ip, $allowed_ips)) {
    $allowed_ips[] = $client_ip;
    file_put_contents($allowed_ips_file, json_encode($allowed_ips));
}

if (in_array($client_ip, $allowed_ips)) {
    echo "<h1>Welcome to the secure page!</h1>";
} else {
    echo "<h1>Access Denied</h1>";
}
?>
