import { z } from 'zod';

export const SetResultSchema = z.object({
    team1: z.number().int().min(0),
    team2: z.number().int().min(0),
});

export const MatchUpdateSchema = z.object({
    team1: z.string().min(1),
    team2: z.string().min(1),
    status: z.enum(['live', 'finished']),
    completedSets: z.array(SetResultSchema).optional(),
    version: z.number().int().optional(),
});

export type MatchUpdateData = z.infer<typeof MatchUpdateSchema>;
