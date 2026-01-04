"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const throttler_1 = require("@nestjs/throttler");
const prisma_module_1 = require("./prisma/prisma.module");
const auth_module_1 = require("./modules/auth/auth.module");
const accounts_module_1 = require("./modules/accounts/accounts.module");
const suppliers_module_1 = require("./modules/suppliers/suppliers.module");
const collections_module_1 = require("./modules/collections/collections.module");
const sales_module_1 = require("./modules/sales/sales.module");
const wallets_module_1 = require("./modules/wallets/wallets.module");
const profile_module_1 = require("./modules/profile/profile.module");
const app_controller_1 = require("./app.controller");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        controllers: [app_controller_1.AppController],
        imports: [
            config_1.ConfigModule.forRoot({
                isGlobal: true,
            }),
            throttler_1.ThrottlerModule.forRoot([
                {
                    ttl: 60000,
                    limit: 100,
                },
            ]),
            prisma_module_1.PrismaModule,
            auth_module_1.AuthModule,
            accounts_module_1.AccountsModule,
            suppliers_module_1.SuppliersModule,
            collections_module_1.CollectionsModule,
            sales_module_1.SalesModule,
            wallets_module_1.WalletsModule,
            profile_module_1.ProfileModule,
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map