export declare class SalesFiltersDto {
    customer_account_code?: string;
    status?: string;
    date_from?: string;
    date_to?: string;
    quantity_min?: number;
    quantity_max?: number;
    price_min?: number;
    price_max?: number;
}
export declare class GetSalesDto {
    filters?: SalesFiltersDto;
}
