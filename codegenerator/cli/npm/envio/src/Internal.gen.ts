/* TypeScript file generated from Internal.res by genType. */

/* eslint-disable */
/* tslint:disable */

import type {invalid as $$noEventFilters} from './bindings/OpaqueTypes.ts';

export abstract class genericEvent<params,block,transaction> { protected opaque!: params | block | transaction }; /* simulate opaque types */

export abstract class genericLoaderArgs<event,context> { protected opaque!: event | context }; /* simulate opaque types */

export type genericLoader<args,loaderReturn> = (_1:args) => Promise<loaderReturn>;

export abstract class genericContractRegisterArgs<event,context> { protected opaque!: event | context }; /* simulate opaque types */

export type genericContractRegister<args> = (_1:args) => void;

export abstract class genericHandlerArgs<event,context,loaderReturn> { protected opaque!: event | context | loaderReturn }; /* simulate opaque types */

export type genericHandler<args> = (_1:args) => Promise<void>;

export abstract class genericHandlerWithLoader<loader,handler,eventFilters> { protected opaque!: loader | handler | eventFilters }; /* simulate opaque types */

export abstract class fuelSupplyParams { protected opaque!: any }; /* simulate opaque types */

export abstract class fuelTransferParams { protected opaque!: any }; /* simulate opaque types */

export type noEventFilters = $$noEventFilters;
