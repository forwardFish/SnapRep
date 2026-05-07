import { registerDecorator, ValidationArguments, ValidationOptions } from 'class-validator';

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const PRISMA_CUID_REGEX = /^c[a-z0-9]{8,}$/;

export function isSessionId(value: unknown): value is string {
    if (typeof value !== 'string') {
        return false;
    }

    return UUID_REGEX.test(value) || PRISMA_CUID_REGEX.test(value);
}

export function IsSessionId(validationOptions?: ValidationOptions) {
    return function (object: object, propertyName: string) {
        registerDecorator({
            name: 'isSessionId',
            target: object.constructor,
            propertyName,
            options: {
                message:
                    '$property must be a valid SnapRep workout session id (Prisma CUID or UUID)',
                ...validationOptions,
            },
            validator: {
                validate(value: unknown) {
                    return isSessionId(value);
                },
                defaultMessage(args: ValidationArguments) {
                    return `${args.property} must be a valid SnapRep workout session id (Prisma CUID or UUID)`;
                },
            },
        });
    };
}
