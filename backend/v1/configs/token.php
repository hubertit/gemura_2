<?php

$jsonData = file_get_contents('php://input');
$data = json_decode($jsonData, true);

if (isset($data["token"])) {
    $token = $data["token"];
} elseif (isset($_GET["token"]))
{
   $token = $_GET["token"];
}else{
    $response = json_encode([
        'code' => 401,
        'status' => "Error",
        'message' => "Access denied"
    ], TRUE);
    print($response);
    exit;
}

$query = mysqli_query($connection, "SELECT * FROM users WHERE  token ='$token'") or die(mysqli_error($connection));
$data = mysqli_fetch_assoc($query);

$userId = $data["user_id"];
