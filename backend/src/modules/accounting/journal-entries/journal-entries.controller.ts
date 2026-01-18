import { Controller, Post, Get, Put, Body, UseGuards, Query, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody, ApiParam, ApiQuery } from '@nestjs/swagger';
import { JournalEntriesService } from './journal-entries.service';
import { TokenGuard } from '../../../common/guards/token.guard';
import { CurrentUser } from '../../../common/decorators/user.decorator';
import { User } from '@prisma/client';
import { CreateJournalEntryDto } from './dto/create-journal-entry.dto';
import { UpdateJournalEntryDto } from './dto/update-journal-entry.dto';

@ApiTags('Accounting - Journal Entries')
@Controller('accounting/journal-entries')
@UseGuards(TokenGuard)
@ApiBearerAuth()
export class JournalEntriesController {
  constructor(private readonly journalEntriesService: JournalEntriesService) {}

  @Post()
  @ApiOperation({ summary: 'Create journal entry' })
  @ApiBody({ type: CreateJournalEntryDto })
  @ApiResponse({ status: 200, description: 'Journal entry created successfully' })
  async createEntry(@CurrentUser() user: User, @Body() createDto: CreateJournalEntryDto) {
    return this.journalEntriesService.createEntry(user, createDto);
  }

  @Get()
  @ApiOperation({ summary: 'List journal entries' })
  @ApiQuery({ name: 'date_from', required: false })
  @ApiQuery({ name: 'date_to', required: false })
  @ApiResponse({ status: 200, description: 'Journal entries fetched successfully' })
  async getEntries(@CurrentUser() user: User, @Query('date_from') dateFrom?: string, @Query('date_to') dateTo?: string) {
    return this.journalEntriesService.getEntries(user, { date_from: dateFrom, date_to: dateTo });
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update journal entry' })
  @ApiParam({ name: 'id' })
  @ApiBody({ type: UpdateJournalEntryDto })
  @ApiResponse({ status: 200, description: 'Journal entry updated successfully' })
  async updateEntry(@CurrentUser() user: User, @Param('id') id: string, @Body() updateDto: UpdateJournalEntryDto) {
    return this.journalEntriesService.updateEntry(user, id, updateDto);
  }
}

