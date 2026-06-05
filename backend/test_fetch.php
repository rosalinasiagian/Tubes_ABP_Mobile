<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
$kernel->handle(Illuminate\Http\Request::capture());

$user = App\Models\User::first();
$token = $user->createToken('test')->plainTextToken;

$request = Illuminate\Http\Request::create('/api/tasks', 'POST', [
    'title' => 'Test',
    'description' => 'Test time',
    'deadline' => '2026-05-23',
    'priority' => 'high',
    'status' => 'pending'
]);
$request->headers->set('Authorization', 'Bearer ' . $token);
$request->headers->set('Accept', 'application/json');

$response = $kernel->handle($request);
echo "Status: " . $response->getStatusCode() . "\n";
echo "Content:\n" . $response->getContent() . "\n";
