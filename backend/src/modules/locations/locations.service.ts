import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { LocationType } from '@prisma/client';

@Injectable()
export class LocationsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Get all provinces (top-level admin units). */
  async getProvinces() {
    return this.prisma.location.findMany({
      where: { location_type: LocationType.PROVINCE },
      orderBy: { name: 'asc' },
      select: { id: true, code: true, name: true, location_type: true, parent_id: true },
    });
  }

  /** Get direct children of a location (e.g. districts of a province, sectors of a district). */
  async getChildren(parentId: string) {
    return this.prisma.location.findMany({
      where: { parent_id: parentId },
      orderBy: { name: 'asc' },
      select: { id: true, code: true, name: true, location_type: true, parent_id: true },
    });
  }

  /** Get a single location by id (for validation / path display). */
  async getById(id: string) {
    return this.prisma.location.findUnique({
      where: { id },
      select: { id: true, code: true, name: true, location_type: true, parent_id: true },
    });
  }

  /** Get path from location up to root (e.g. [village, cell, sector, district, province]) for display. */
  async getPath(id: string): Promise<{ id: string; code: string; name: string; location_type: string }[]> {
    const path: { id: string; code: string; name: string; location_type: string }[] = [];
    let current = await this.prisma.location.findUnique({
      where: { id },
      select: { id: true, code: true, name: true, location_type: true, parent_id: true },
    });
    while (current) {
      path.unshift({
        id: current.id,
        code: current.code,
        name: current.name,
        location_type: current.location_type,
      });
      if (!current.parent_id) break;
      current = await this.prisma.location.findUnique({
        where: { id: current.parent_id },
        select: { id: true, code: true, name: true, location_type: true, parent_id: true },
      });
    }
    return path;
  }
}
