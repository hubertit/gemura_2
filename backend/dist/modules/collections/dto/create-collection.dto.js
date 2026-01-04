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
exports.CreateCollectionDto = void 0;
const swagger_1 = require("@nestjs/swagger");
const class_validator_1 = require("class-validator");
class CreateCollectionDto {
}
exports.CreateCollectionDto = CreateCollectionDto;
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Supplier account code (from supplier creation)',
        example: 'A_ABC123',
        required: true,
    }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Supplier account code is required' }),
    (0, class_validator_1.IsString)({ message: 'Supplier account code must be a string' }),
    __metadata("design:type", String)
], CreateCollectionDto.prototype, "supplier_account_code", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Quantity of milk collected in liters',
        example: 120.5,
        minimum: 0.01,
        required: true,
    }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Quantity is required' }),
    (0, class_validator_1.IsNumber)({}, { message: 'Quantity must be a number' }),
    __metadata("design:type", Number)
], CreateCollectionDto.prototype, "quantity", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Collection status',
        example: 'pending',
        enum: ['pending', 'completed', 'cancelled'],
        required: true,
    }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Status is required' }),
    (0, class_validator_1.IsString)({ message: 'Status must be a string' }),
    __metadata("design:type", String)
], CreateCollectionDto.prototype, "status", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Collection date and time in format: YYYY-MM-DD HH:mm:ss',
        example: '2025-01-04 10:00:00',
        required: true,
    }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Collection date/time is required' }),
    (0, class_validator_1.IsString)({ message: 'Collection date/time must be a string' }),
    __metadata("design:type", String)
], CreateCollectionDto.prototype, "collection_at", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Additional notes about the collection (optional)',
        example: 'Morning collection, good quality milk',
        required: false,
    }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)({ message: 'Notes must be a string' }),
    __metadata("design:type", String)
], CreateCollectionDto.prototype, "notes", void 0);
//# sourceMappingURL=create-collection.dto.js.map