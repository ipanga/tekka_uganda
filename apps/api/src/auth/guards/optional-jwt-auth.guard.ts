import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtPayload } from '../auth.service';

/**
 * JWT guard that parses the Bearer token when present and attaches the user
 * to `request.user`, but does NOT reject when the token is missing or
 * invalid. Use this on endpoints that have both an authenticated and a
 * guest behaviour path (e.g. tracking beacons that no-op for guests).
 *
 * Mirrors the strict `JwtAuthGuard` (./jwt-auth.guard.ts) — same token
 * parser, same user lookup, same suspension check — but never throws. The
 * controller decides what to do with `null` via `@CurrentUser()`.
 */
@Injectable()
export class OptionalJwtAuthGuard implements CanActivate {
  constructor(
    private jwtService: JwtService,
    private prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const token = this.extractTokenFromHeader(request);

    if (!token) return true; // Guest — leave request.user undefined.

    try {
      const payload = this.jwtService.verify<JwtPayload>(token);
      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });
      if (user && !user.isSuspended) {
        request.user = user;
      }
    } catch {
      // Malformed / expired token — treat as guest. Never throws.
    }

    return true;
  }

  private extractTokenFromHeader(request: any): string | undefined {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}
