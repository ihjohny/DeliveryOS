import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface Response<T> {
  success: boolean;
  statusCode: number;
  message: string;
  data: T;
}

@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<T, Response<T>> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<Response<T>> {
    const ctx = context.switchToHttp();
    const response = ctx.getResponse();
    const statusCode = response.statusCode || 200;

    return next.handle().pipe(
      map((resData) => {
        // If the handler already returned an object with message and data
        if (resData && typeof resData === 'object' && 'data' in resData) {
          return {
            success: true,
            statusCode,
            message: resData.message || 'Operation successful',
            data: resData.data,
          };
        }
        return {
          success: true,
          statusCode,
          message: 'Operation successful',
          data: resData ?? {},
        };
      }),
    );
  }
}
