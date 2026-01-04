export declare class AccountDto {
    account_id: string;
    account_code: string;
    account_name: string;
    account_type: string;
    account_status: string;
    account_created_at: Date;
    role: string;
    permissions: any;
    user_account_status: string;
    access_granted_at: Date;
    is_default: boolean;
}
export declare class UserDto {
    id: string;
    name: string;
    email: string | null;
    phone: string | null;
    account_type: string;
    status: string;
    token: string | null;
}
export declare class DefaultAccountDto {
    id: string;
    code: string;
    name: string;
    type: string;
}
export declare class LoginResponseDataDto {
    user: UserDto;
    account: DefaultAccountDto | null;
    accounts: AccountDto[];
    total_accounts: number;
    profile_completion: number;
}
export declare class AuthResponseDto {
    code: number;
    status: string;
    message: string;
    data: LoginResponseDataDto;
}
