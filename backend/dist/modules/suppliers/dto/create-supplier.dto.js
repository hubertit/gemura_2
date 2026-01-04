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
exports.CreateSupplierDto = void 0;
const swagger_1 = require("@nestjs/swagger");
const class_validator_1 = require("class-validator");
class CreateSupplierDto {
}
exports.CreateSupplierDto = CreateSupplierDto;
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Full name of the supplier',
        example: 'John Doe',
        required: true,
    }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Supplier name is required' }),
    (0, class_validator_1.IsString)({ message: 'Supplier name must be a string' }),
    __metadata("design:type", String)
], CreateSupplierDto.prototype, "name", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Supplier phone number in Rwandan format (250XXXXXXXXX)',
        example: '250788123456',
        pattern: '^250[0-9]{9}$',
        required: true,
    }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Phone number is required' }),
    (0, class_validator_1.IsString)({ message: 'Phone number must be a string' }),
    __metadata("design:type", String)
], CreateSupplierDto.prototype, "phone", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Price per liter of milk in RWF',
        example: 390.0,
        minimum: 0,
        required: true,
    }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Price per liter is required' }),
    (0, class_validator_1.IsNumber)({}, { message: 'Price per liter must be a number' }),
    __metadata("design:type", Number)
], CreateSupplierDto.prototype, "price_per_liter", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Supplier email address (optional)',
        example: 'supplier@example.com',
        required: false,
    }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)({ message: 'Email must be a string' }),
    __metadata("design:type", String)
], CreateSupplierDto.prototype, "email", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'National ID number (optional)',
        example: '1199887766554433',
        required: false,
    }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)({ message: 'National ID must be a string' }),
    __metadata("design:type", String)
], CreateSupplierDto.prototype, "nid", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Physical address (optional)',
        example: 'Kigali, Rwanda',
        required: false,
    }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)({ message: 'Address must be a string' }),
    __metadata("design:type", String)
], CreateSupplierDto.prototype, "address", void 0);
//# sourceMappingURL=create-supplier.dto.js.map