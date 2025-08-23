<?php
require_once("/Applications/AMPPS/www/gemura2/api/v2/configs/configs.php");

// Migration Script for Old Users to New System
echo "🔄 Starting User Migration from Old System...\n\n";

// Sample users from old system (first 5 active users)
$oldUsers = [
    [
        'user_id' => 3,
        'user_code' => 'G03',
        'user_fname' => 'MCC',
        'user_lname' => 'Nyagatare',
        'user_email' => 'hubert@devslab.io',
        'user_phone' => '0788606765',
        'user_password' => '5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8', // SHA1 hash
        'user_status' => 'active',
        'wallet_balance' => 10,
        'province_id' => 2,
        'district_id' => 25,
        'user_category' => 'Admin'
    ],
    [
        'user_id' => 5,
        'user_code' => 'G05',
        'user_fname' => 'Alex',
        'user_lname' => 'Ntare',
        'user_email' => 'ntalea@gmail.com',
        'user_phone' => '0784968343',
        'user_password' => '5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8',
        'user_status' => 'active',
        'wallet_balance' => 6000,
        'province_id' => 5,
        'district_id' => 25,
        'user_category' => 'Admin'
    ],
    [
        'user_id' => 6,
        'user_code' => 'G06',
        'user_fname' => 'Ivy',
        'user_lname' => 'Nyamvumba',
        'user_email' => 'nyamvumbaivy@gmail.com',
        'user_phone' => '0789127177',
        'user_password' => 'f2c57870308dc87f432e5912d4de6f8e322721ba',
        'user_status' => 'active',
        'wallet_balance' => 0,
        'province_id' => 4,
        'district_id' => 23,
        'user_category' => 'Farmer'
    ],
    [
        'user_id' => 14,
        'user_code' => 'G014',
        'user_fname' => 'Fab cafe',
        'user_lname' => '',
        'user_email' => '',
        'user_phone' => '0787656566',
        'user_password' => '5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8',
        'user_status' => 'active',
        'wallet_balance' => 0,
        'province_id' => 4,
        'district_id' => 23,
        'user_category' => 'Farmer'
    ],
    [
        'user_id' => 51,
        'user_code' => 'G051',
        'user_fname' => 'peter',
        'user_lname' => '',
        'user_email' => '',
        'user_phone' => '0782628631',
        'user_password' => '5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8',
        'user_status' => 'active',
        'wallet_balance' => 0,
        'province_id' => 4,
        'district_id' => 23,
        'user_category' => 'Farmer'
    ]
];

// Data cleaning and mapping functions
function cleanPhone($phone) {
    // Remove any non-numeric characters
    $cleaned = preg_replace('/[^0-9]/', '', $phone);
    
    // Ensure proper Rwanda phone format
    if (strlen($cleaned) == 10 && substr($cleaned, 0, 1) == '0') {
        return $cleaned; // Keep as is: 0788606765
    } elseif (strlen($cleaned) == 9) {
        return '0' . $cleaned; // Add leading 0: 788606765 -> 0788606765
    } elseif (strlen($cleaned) == 12 && substr($cleaned, 0, 3) == '250') {
        return '0' . substr($cleaned, 3); // Convert 250788606765 -> 0788606765
    }
    
    return $cleaned; // Return as is if no pattern matches
}

function cleanEmail($email) {
    $email = trim($email);
    if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        return null;
    }
    return strtolower($email);
}

function cleanName($fname, $lname) {
    $name = trim($fname . ' ' . $lname);
    return empty($name) ? 'Migrated User' : $name;
}

function mapRole($userCategory) {
    switch (strtolower($userCategory)) {
        case 'admin':
            return 'admin';
        case 'farmer':
            return 'supplier';
        default:
            return 'customer';
    }
}

function generateNewCode($prefix) {
    return $prefix . '_' . strtoupper(bin2hex(random_bytes(3)));
}

function generateRandomPassword() {
    // Generate 5-digit random password
    return str_pad(rand(10000, 99999), 5, '0', STR_PAD_LEFT);
}

// Migration process
$migrated = 0;
$errors = [];

foreach ($oldUsers as $oldUser) {
    echo "📝 Migrating user: {$oldUser['user_fname']} {$oldUser['user_lname']} ({$oldUser['user_phone']})\n";
    
    try {
        $connection->begin_transaction();
        
        // Clean and prepare data
        $name = cleanName($oldUser['user_fname'], $oldUser['user_lname']);
        $email = cleanEmail($oldUser['user_email']);
        $phone = cleanPhone($oldUser['user_phone']);
        $role = mapRole($oldUser['user_category']);
        $status = $oldUser['user_status'] === 'active' ? 'active' : 'pending';
        
        // Generate new codes
        $user_code = generateNewCode('U');
        $account_code = generateNewCode('A');
        $wallet_code = generateNewCode('W');
        
        // Generate random 5-digit password
        $random_password = generateRandomPassword();
        $password_hash = password_hash($random_password, PASSWORD_BCRYPT);
        $token = bin2hex(random_bytes(32));
        
        echo "   📧 Email: " . ($email ?: 'None') . "\n";
        echo "   📱 Phone: $phone\n";
        echo "   👤 Role: $role\n";
        echo "   💰 Balance: {$oldUser['wallet_balance']} RWF\n";
        
        // Check if user already exists
        $stmt = $connection->prepare("SELECT id FROM users WHERE phone = ? LIMIT 1");
        $stmt->bind_param("s", $phone);
        $stmt->execute();
        $stmt->store_result();
        
        if ($stmt->num_rows > 0) {
            echo "   ⚠️  User already exists, skipping...\n\n";
            $stmt->close();
            $connection->rollback();
            continue;
        }
        $stmt->close();
        
        // 1. Create user
        $stmt = $connection->prepare("
            INSERT INTO users (code, name, email, phone, password_hash, token, status, created_by)
            VALUES (?, ?, ?, ?, ?, ?, ?, 1)
        ");
        if (!$stmt) {
            throw new Exception("Failed to prepare user statement: " . $connection->error);
        }
        $stmt->bind_param("sssssss", $user_code, $name, $email, $phone, $password_hash, $token, $status);
        $stmt->execute();
        $user_id = $stmt->insert_id;
        $stmt->close();
        
        // 2. Create account
        $account_name = $name . "'s Account";
        $stmt = $connection->prepare("
            INSERT INTO accounts (code, name, type, status, created_by)
            VALUES (?, ?, 'tenant', 'active', ?)
        ");
        if (!$stmt) {
            throw new Exception("Failed to prepare account statement: " . $connection->error);
        }
        $stmt->bind_param("ssi", $account_code, $account_name, $user_id);
        $stmt->execute();
        $account_id = $stmt->insert_id;
        $stmt->close();
        
        // 3. Link user to account
        $permissions = json_encode([
            'can_collect' => true,
            'can_add_supplier' => true,
            'can_view_reports' => true
        ]);
        
        $stmt = $connection->prepare("
            INSERT INTO user_accounts (user_id, account_id, role, permissions, status, created_by)
            VALUES (?, ?, ?, ?, 'active', ?)
        ");
        if (!$stmt) {
            throw new Exception("Failed to prepare user_accounts statement: " . $connection->error);
        }
        $stmt->bind_param("iissi", $user_id, $account_id, $role, $permissions, $user_id);
        $stmt->execute();
        $stmt->close();
        
        // 4. Create wallet with migrated balance
        $balance = (float)$oldUser['wallet_balance'];
        $stmt = $connection->prepare("
            INSERT INTO wallets (account_id, code, type, is_joint, balance, currency, status, is_default, created_by)
            VALUES (?, ?, 'regular', 0, ?, 'RWF', 'active', 1, ?)
        ");
        if (!$stmt) {
            throw new Exception("Failed to prepare wallet statement: " . $connection->error);
        }
        $stmt->bind_param("isdi", $account_id, $wallet_code, $balance, $user_id);
        $stmt->execute();
        $stmt->close();
        
        // 5. Update user's default account
        $stmt = $connection->prepare("UPDATE users SET default_account_id = ? WHERE id = ?");
        if ($stmt) {
            $stmt->bind_param("ii", $account_id, $user_id);
            $stmt->execute();
            $stmt->close();
        }
        
        $connection->commit();
        $migrated++;
        
        echo "   ✅ Successfully migrated!\n";
        echo "   🆔 New User Code: $user_code\n";
        echo "   🏢 Account Code: $account_code\n";
        echo "   💳 Wallet Code: $wallet_code\n";
        echo "   🔑 Password: $random_password\n\n";
        
    } catch (Exception $e) {
        $connection->rollback();
        $error_msg = "❌ Failed to migrate {$oldUser['user_phone']}: " . $e->getMessage();
        echo "   $error_msg\n\n";
        $errors[] = $error_msg;
    }
}

echo "\n🎯 Migration Summary:\n";
echo "   ✅ Successfully migrated: $migrated users\n";
echo "   ❌ Errors: " . count($errors) . "\n";

if (!empty($errors)) {
    echo "\n❌ Error Details:\n";
    foreach ($errors as $error) {
        echo "   $error\n";
    }
}

echo "\n📋 Next Steps:\n";
echo "   1. Test login with migrated users using their 5-digit passwords\n";
echo "   2. Users can optionally change their passwords\n";
echo "   3. Verify wallet balances are correct\n";
echo "   4. Check account permissions\n";

?>
