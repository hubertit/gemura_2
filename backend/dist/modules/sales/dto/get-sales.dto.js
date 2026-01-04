"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.GetSalesDto = exports.SalesFiltersDto = void 0;
const swagger_1 = require("@nestjs/swagger");
const class_validator_1 = require("class-validator");
class SalesFiltersDto {
}
exports.SalesFiltersDto = SalesFiltersDto;
__decorate([
    (0, swagger_1.ApiProperty)({ required: false, description: 'Customer account code' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], SalesFiltersDto.prototype, "customer_account_code", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ required: false, description: 'Sale status' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], SalesFiltersDto.prototype, "status", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ required: false, description: 'Date from (YYYY-MM-DD)' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], SalesFiltersDto.prototype, "date_from", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ required: false, description: 'Date to (YYYY-MM-DD)' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], SalesFiltersDto.prototype, "date_to", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ required: false, description: 'Minimum quantity' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], SalesFiltersDto.prototype, "quantity_min", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ required: false, description: 'Maximum quantity' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], SalesFiltersDto.prototype, "quantity_max", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ required: false, description: 'Minimum price' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], SalesFiltersDto.prototype, "price_min", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ required: false, description: 'Maximum price' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], SalesFiltersDto.prototype, "price_max", void 0);
class GetSalesDto {
}
exports.GetSalesDto = GetSalesDto;
__decorate([
    (0, swagger_1.ApiProperty)({ type: SalesFiltersDto, required: false }),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", SalesFiltersDto)
], GetSalesDto.prototype, "filters", void 0);
//# sourceMappingURL=get-sales.dto.js.map