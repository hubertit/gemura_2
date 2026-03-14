import {
  registerDecorator,
  ValidationOptions,
  ValidationArguments,
} from 'class-validator';

/**
 * Validates that the date/datetime string is not in the future (today is allowed).
 * Use for: date of birth, purchase date, event date, recorded_at, sale_at, etc.
 */
export function IsNotFutureDate(validationOptions?: ValidationOptions) {
  return function (object: Object, propertyName: string) {
    registerDecorator({
      name: 'isNotFutureDate',
      target: object.constructor,
      propertyName,
      options: validationOptions,
      validator: {
        validate(value: unknown): boolean {
          if (value == null || value === '') return true;
          const d = new Date(value as string);
          if (Number.isNaN(d.getTime())) return false;
          // Allow up to 5 minutes in the future to account for clock skew and network delays
          const fiveMinutesFromNow = Date.now() + (5 * 60 * 1000);
          return d.getTime() <= fiveMinutesFromNow;
        },
        defaultMessage(args: ValidationArguments): string {
          return `${args.property} must not be a future date`;
        },
      },
    });
  };
}
