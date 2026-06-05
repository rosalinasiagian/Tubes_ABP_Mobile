<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

$user = App\Models\User::first();
$token = $user->createToken('test')->plainTextToken;

$response = Http::withToken($token)
    ->post('http://127.0.0.1:8001/api/tasks', [
        'title' => 'Test',
        'priority' => 'medium',
        'status' => 'pending',
        'deadline' => '2026-05-23'
    ]);

echo "Status: " . $response->status() . "\n";
echo "Body: " . $response->body() . "\n";
